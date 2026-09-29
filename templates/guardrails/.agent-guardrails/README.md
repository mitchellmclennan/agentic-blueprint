# Write-time guardrails

These deterministic checks run locally and never grant permission. The OpenCode plugin and Claude hooks check obvious destructive Bash commands and writes outside the checkout or to credentials. The Git pre-commit checks staged bytes for credential patterns, conflict markers, whitespace, JSON/Python/shell syntax. CI and review remain required: shell syntax matching is not a sandbox, Git hooks can be bypassed, and staged checks do not run the whole test suite. Post-tool hook leaves outcomes visible and cannot undo a completed action.

Run `bash .agent-guardrails/install.sh` **in each checkout/worktree** to activate the tracked pre-commit hook. The installer refuses if `core.hooksPath` already exists and never overwrites existing hooks. Worktree-local config requires `extensions.worktreeConfig`; the owner must enable it explicitly. Use the repo's actual CI command before PR review. Do not use `--no-verify` as a routine workaround.

`.claude/settings.json` uses `${CLAUDE_PROJECT_DIR}` for an absolute hook path, so it works after a tool changes cwd. It binds the PreToolUse/PostToolUse events to `.claude/hooks/guard.sh`; OpenCode auto-loads `.opencode/plugins/guardrails.js`. These are not global operating-system controls. Topic rules in `.claude/rules` are guidance, not deterministic enforcement.

The blueprint provides `.claude/settings.guardrails.json` as a merge-only snippet. Deployed repositories merge its hooks into `.claude/settings.json`, preserving existing settings and hooks. The snippet alone is not a loaded settings file.
