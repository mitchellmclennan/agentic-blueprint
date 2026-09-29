# Write-time guardrails

These deterministic checks run locally and never grant permission. The OpenCode plugin and Claude hooks check obvious destructive Bash commands and writes outside the checkout or to credentials. The Git pre-commit checks staged bytes for credential patterns, conflict markers, whitespace, JSON/Python/shell syntax. CI and review remain required: shell syntax matching is not a sandbox, Git hooks can be bypassed, and staged checks do not run the whole test suite. Post-tool hook leaves outcomes visible and cannot undo a completed action.

Run `bash .agent-guardrails/install.sh` **in each checkout/worktree** to activate the tracked pre-commit hook. Git's worktree-local config requires `extensions.worktreeConfig`; the installer must not silently alter a shared worktree if unsupported. Use the repo's actual CI command before PR review. Do not use `--no-verify` as a routine workaround.

`.claude/settings.json` binds the PreToolUse/PostToolUse events to `.claude/hooks/guard.sh`; OpenCode auto-loads `.opencode/plugins/guardrails.js`. These are not global operating-system controls. Topic rules in `.claude/rules` and `.opencode/skills` are guidance, not deterministic enforcement.

The `settings.guardrails.json` file is a snippet to merge into an existing `.claude/settings.json`, not a second loaded settings file. Existing project hooks and permissions must be retained.
