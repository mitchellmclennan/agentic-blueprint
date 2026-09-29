#!/usr/bin/env bash
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"
# Worktrees may share Git metadata. This per-worktree config affects this checkout only.
if git rev-parse --is-bare-repository | grep -qx true; then echo "Bare repository not supported" >&2; exit 1; fi
if ! git config --local --get extensions.worktreeConfig | grep -qx true; then
  echo "Worktree-local config is not enabled. Have the repository owner run git config extensions.worktreeConfig true before installing; no shared config changed." >&2
  exit 1
fi
git config --worktree core.hooksPath .agent-guardrails
printf 'Guardrails installed in %s\n' "$root"
