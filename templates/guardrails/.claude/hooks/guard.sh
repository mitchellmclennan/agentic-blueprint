#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/../.."
case "${1:-}" in
  pre) exec python3 .agent-guardrails/guard.py tool ;;
  post) exec python3 .agent-guardrails/guard.py post ;;
  *) echo 'Unknown hook phase' >&2; exit 2 ;;
esac
