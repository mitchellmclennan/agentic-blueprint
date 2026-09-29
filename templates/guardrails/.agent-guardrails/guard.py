#!/usr/bin/env python3
"""Deterministic, local, no-network write-time checks. Never grants permission."""
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BAD_COMMANDS = [
    (r'(?i)\bgit\s+push\s+(?:[^;&|\n]*\s)?(?:--force(?:-with-lease)?|-f)\b', 'force push'),
    (r'(?i)\b(?:drop\s+(?:table|database)|truncate\s+table)\b', 'destructive SQL'),
]
PROTECTED = re.compile(r'(^|/)(?:\.env(?:\..*)?|\.git/.*|id_(?:rsa|ed25519).*|.*\.(?:pem|key|p12))$')
SECRET = re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----|(?:AKIA|ASIA)[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{30,}|github_pat_[A-Za-z0-9_]{30,}')
CONFLICT = re.compile(r'^(?:<<<<<<< |=======\s*$|>>>>>>> )', re.M)


def deny(message):
    print('Guardrail blocked: ' + message, file=sys.stderr)
    return 2


def check_command(command):
    # shlex retains quoted operators as data and emits real shell operators.
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=';&|')
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return deny('unparseable shell command')
    segments = []
    operators = []
    current = []
    for token in tokens:
        if token and set(token) <= set(';&|'):
            segments.append(current)
            operators.append(token)
            current = []
        else:
            current.append(token)
    segments.append(current)
    pipeline_has_fetch = False
    for idx, segment in enumerate(segments):
        if idx == 0 or '|' not in operators[idx - 1]:
            pipeline_has_fetch = False
        if not segment: continue
        if pipeline_has_fetch:
            sink = segment[:]
            if sink and sink[0].rsplit('/', 1)[-1] == 'env':
                sink = sink[1:]
                while sink and sink[0].startswith('-'):
                    # env -i / -u NAME / --unset=NAME; conservative skip for env options.
                    if sink[0] in ('-u', '--unset') and len(sink) > 1: sink = sink[2:]
                    else: sink = sink[1:]
                while sink and '=' in sink[0] and not sink[0].startswith('='):
                    sink = sink[1:]
            if sink and sink[0].rsplit('/', 1)[-1] in ('bash', 'sh'):
                return deny('download-and-execute; use a reviewed, scoped alternative')
        if any(t.rsplit('/', 1)[-1] in ('curl', 'wget') for t in segment):
            pipeline_has_fetch = True
        for pos, token in enumerate(segment):
            executable = token.rsplit('/', 1)[-1]
            if executable == 'rm':
                recursive = force = False
                for flag in segment[pos + 1:]:
                    if flag == '--': break
                    if flag == '--recursive': recursive = True
                    elif flag == '--force': force = True
                    elif flag.startswith('-') and not flag.startswith('--'):
                        recursive |= any(ch in flag[1:] for ch in 'rR')
                        force |= 'f' in flag[1:]
                if recursive and force:
                    return deny('recursive forced removal; use a reviewed, scoped alternative')
            if executable == 'git':
                args = segment[pos + 1:]
                i = 0
                while i < len(args):
                    opt = args[i]
                    if opt in ('-C', '-c', '--git-dir', '--work-tree', '--namespace', '--config-env'):
                        i += 2
                    elif opt.startswith(('-C', '-c', '--git-dir=', '--work-tree=', '--namespace=', '--config-env=')) and opt not in ('-C', '-c'):
                        i += 1
                    elif opt in ('--no-pager', '--paginate', '-p', '-P', '--bare', '--no-replace-objects', '--literal-pathspecs', '--no-optional-locks'):
                        i += 1
                    else:
                        break
                if i >= len(args): continue
                verb, rest = args[i], args[i + 1:]
                if verb == 'reset' and any(flag == '--hard' or flag.startswith('--hard=') for flag in rest):
                    return deny('destructive git reset; use a reviewed, scoped alternative')
                if verb == 'clean' and any(t == '--force' or (t.startswith('-') and not t.startswith('--') and 'f' in t[1:]) for t in rest):
                    return deny('destructive git clean; use a reviewed, scoped alternative')
                if verb == 'push' and any(t in ('-f', '--force', '--force-with-lease') or t.startswith('--force-with-lease=') for t in rest):
                    return deny('force push; use a reviewed, scoped alternative')
        # SQL is checked on actual unquoted command text as a conservative secondary filter.
        for pattern, reason in BAD_COMMANDS:
            if re.search(pattern, ' '.join(segment)):
                return deny(reason + '; use a reviewed, scoped alternative')
    return 0


def check_path(raw):
    if not isinstance(raw, str) or not raw.strip():
        return deny('missing write destination')
    path = Path(raw)
    absolute = (path if path.is_absolute() else ROOT / path).resolve()
    if not absolute.is_relative_to(ROOT.resolve()):
        return deny('write outside repository')
    relative = absolute.relative_to(ROOT.resolve()).as_posix()
    if PROTECTED.search(relative):
        return deny('protected path ' + relative)
    return 0


def tool(event):
    name = str(event.get('tool_name') or event.get('tool') or '').lower()
    args = event.get('tool_input') or event.get('args') or {}
    if not isinstance(args, dict):
        return deny('unknown tool arguments')
    if name in ('bash', 'shell'):
        return check_command(str(args.get('command') or ''))
    if name in ('write', 'edit', 'multiedit', 'apply_patch', 'patch'):
        paths = []
        def collect(value):
            if isinstance(value, dict):
                for key, item in value.items():
                    if key in ('path', 'file_path', 'filePath', 'destination_path', 'destinationPath', 'output_path', 'outputPath'):
                        paths.extend(item if isinstance(item, list) else [item])
                    elif isinstance(item, (dict, list)):
                        collect(item)
            elif isinstance(value, list):
                for item in value: collect(item)
        collect(args)
        if not paths:
            return deny('write path not inspectable')
        for path in paths:
            status = check_path(path)
            if status: return status
        return 0
    return 0


def staged():
    result = subprocess.run(['git', 'diff', '--cached', '--name-only', '-z', '--diff-filter=ACMR'], cwd=ROOT, capture_output=True)
    if result.returncode:
        return deny('cannot read staged paths')
    names = [n.decode('utf-8', 'surrogateescape') for n in result.stdout.split(b'\0') if n]
    failures = []
    for name in names:
        if PROTECTED.search(name):
            failures.append(name + ': protected file')
            continue
        raw = subprocess.run(['git', 'show', ':' + name], cwd=ROOT, capture_output=True)
        if raw.returncode:
            failures.append(name + ': cannot inspect staged bytes')
            continue
        data = raw.stdout
        if b'\0' in data[:8192]:
            continue
        text = data.decode('utf-8', 'replace')
        if SECRET.search(text):
            failures.append(name + ': credential-like material')
        if CONFLICT.search(text):
            failures.append(name + ': conflict marker')
        if name.endswith('.py'):
            try:
                compile(text, name, 'exec')
            except SyntaxError as exc:
                failures.append(f'{name}: Python syntax line {exc.lineno}')
        if name.endswith('.json'):
            try:
                json.loads(text)
            except json.JSONDecodeError as exc:
                failures.append(f'{name}: JSON syntax line {exc.lineno}')
        if name.endswith(('.sh', '.bash')):
            check = subprocess.run(['bash', '-n'], input=data, capture_output=True)
            if check.returncode:
                failures.append(name + ': shell syntax')
    if failures:
        return deny('; '.join(failures))
    whitespace = subprocess.run(['git', 'diff', '--cached', '--check'], cwd=ROOT, capture_output=True, text=True)
    if whitespace.returncode:
        return deny('staged whitespace errors: ' + whitespace.stdout[:600])
    return 0


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ''
    if action == 'tool':
        try:
            return tool(json.load(sys.stdin))
        except (ValueError, TypeError):
            return deny('unreadable tool input')
    if action == 'staged':
        return staged()
    if action == 'post':
        return 0  # Post-tool is observability only; mutations already occurred.
    return deny('unknown guardrail action')


if __name__ == '__main__':
    sys.exit(main())
