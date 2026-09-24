#!/usr/bin/env bash
# agentic-blueprint bootstrap: install/upgrade the stack into a repo. IDEMPOTENT.
# Usage: install.sh /path/to/target-repo
# Rules: files we manage carry a "# stack-version:" marker. We overwrite managed files only
# when the marker is older; we NEVER touch unmanaged (locally-authored) files - we warn.
set -euo pipefail
STACK_VER="0.1.0"
STACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:?usage: install.sh /path/to/repo}"
cd "$TARGET"
[ -d .git ] || { echo "x not a git repo: $TARGET"; exit 1; }
changed=0; skipped=0

install_file() { # $1 = source (relative to stack repo), $2 = dest (relative to target)
  local src="$STACK_DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"; echo "  + $dst (new)"; changed=1; return
  fi
  local cur
  cur=$(grep -m1 -oE "stack-version: [0-9.]+" "$dst" | grep -oE "[0-9.]+" || echo "")
  if [ -z "$cur" ]; then
    echo "  ! $dst exists WITHOUT stack marker - leaving untouched (local file; merge manually)"; skipped=1; return
  fi
  if [ "$cur" = "$STACK_VER" ]; then
    echo "  = $dst (current, $cur)"; return
  fi
  cp "$src" "$dst"; echo "  ^ $dst ($cur -> $STACK_VER)"; changed=1
}

echo "agentic-blueprint bootstrap v$STACK_VER -> $(basename "$TARGET")"
install_file "templates/stack.yaml" "stack.yaml"
install_file "templates/callers/ci.yml" ".github/workflows/ci.yml"
install_file "templates/callers/security.yml" ".github/workflows/security.yml"
install_file "templates/callers/stack-sync.yml" ".github/workflows/stack-sync.yml"
install_file "templates/PULL_REQUEST_TEMPLATE.md" ".github/PULL_REQUEST_TEMPLATE.md"
if [ $changed -eq 1 ]; then echo "done: changes applied"; else echo "done: already current (no-op)"; fi
[ $skipped -eq 1 ] && echo "note: local unmarked files skipped (merge manually)"
echo "next: commit + push; then wire branch protection and confirm the board project number var (PRJ_NUMBER)."
