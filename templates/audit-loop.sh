#!/usr/bin/env bash
# audit-loop - skeleton: run a check, diff against baseline, alert on delta.
# Contract: exit 0 = no delta; exit 10 = NEW FINDINGS (details in log).
set -uo pipefail
NAME=${NAME:-my-audit}
BASE=${BASE:-$HOME/audit-fleet/baseline/$NAME.jsonl}
LOG=${LOG:-$HOME/audit-fleet/logs/$NAME.log}
CUR=$(mktemp)
mkdir -p "$(dirname "$BASE")" "$(dirname "$LOG")"
echo "=== $(date -Is) $NAME run ===" >> "$LOG"

# --- replace this line: emit one canonical line per finding, sorted ---
run_check > "$CUR"
# ---------------------------------------------------------------------

if [ ! -f "$BASE" ]; then
  cp "$CUR" "$BASE"; echo "baseline written ($(wc -l < "$BASE") rows)" >> "$LOG"; rm -f "$CUR"; exit 0
fi
NEW=$(comm -13 <(sort "$BASE") <(sort "$CUR"))
if [ -n "$NEW" ]; then
  { echo "!!! NEW FINDINGS ($NAME) $(date -Is)"; echo "$NEW"; } >> "$LOG"
  rm -f "$CUR"; exit 10
fi
echo "ok (no delta)" >> "$LOG"; rm -f "$CUR"; exit 0
