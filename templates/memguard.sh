#!/usr/bin/env bash
# memguard - TERM then KILL the largest-RSS process in sacrificial slices
# when available memory drops below the floor. Never touches system.slice
# or the model service. Log every action.
set -u
FLOOR_MB=${FLOOR_MB:-1536}
LOG=${LOG:-$HOME/memguard.log}
while true; do
  avail=$(awk "/MemAvailable/{print int(\$2/1024)}" /proc/meminfo)
  if [ "$avail" -lt "$FLOOR_MB" ]; then
    for slice in batch.slice lanes.slice; do
      pid=$(systemd-cgls --no-page "/user.slice/$slice" 2>/dev/null | awk "{print \$1}" | grep -E "^[0-9]+$" | while read p; do
        rss=$(awk "/VmRSS/{print \$2}" /proc/$p/status 2>/dev/null || echo 0)
        echo "$rss $p"
      done | sort -rn | head -1 | awk "{print \$2}")
      if [ -n "${pid:-}" ]; then
        echo "$(date -Is) avail=${avail}MB TERM $pid in $slice" >> "$LOG"
        kill -TERM "$pid" 2>/dev/null; sleep 8
        kill -0 "$pid" 2>/dev/null && { echo "$(date -Is) KILL $pid" >> "$LOG"; kill -KILL "$pid"; }
      fi
      avail=$(awk "/MemAvailable/{print int(\$2/1024)}" /proc/meminfo)
      [ "$avail" -ge "$FLOOR_MB" ] && break
    done
  fi
  sleep 5
done
