#!/usr/bin/env bash
# box bootstrap: memguard + slice caps + access-path OOM protection on a fresh box.
# Reads budgets from stack.yaml (box: section). Run as root for the system parts:
#   sudo bash bootstrap-box.sh [path-to-stack.yaml]
set -euo pipefail
YAML="${1:-stack.yaml}"
get() { grep -A6 "^box:" "$YAML" | grep -E "^\s+$1:" | grep -oE "[0-9]+" | head -1; }
LAYA=$(get laya); BATCH=$(get batch); CI=$(get ci); LANES=$(get lanes); FLOOR=$(get memguard_floor_mb)
USER_NAME="${SUDO_USER:-$USER}"

# access path dies last
mkdir -p /etc/systemd/system/cloudflared.service.d /etc/systemd/system/ssh.service.d /etc/systemd/system/sshd.service.d /etc/systemd/system/tailscaled.service.d
for u in cloudflared ssh sshd tailscaled; do
  printf '[Service]\nOOMScoreAdjust=-1000\n' > /etc/systemd/system/$u.service.d/oom-protect.conf
done
command -v earlyoom >/dev/null || { apt-get update -qq && apt-get install -y -qq earlyoom; }
printf 'EARLYOOM_ARGS="-m 5 -s 30 -r 60"\n' > /etc/default/earlyoom
systemctl enable --now earlyoom

# slice caps (user manager of the invoking user)
U=/home/$USER_NAME/.config/systemd/user
mkdir -p $U/laya.slice.d $U/ci.slice.d $U/batch.slice.d $U/lanes.slice.d
printf "[Slice]\nMemoryMax=${LAYA}M\n"  > $U/laya.slice.d/cap.conf
printf "[Slice]\nMemoryMax=${BATCH}M\n" > $U/batch.slice.d/cap.conf
printf "[Slice]\nMemoryMax=${CI}M\n"    > $U/ci.slice.d/cap.conf
printf "[Slice]\nMemoryMax=${LANES}M\n" > $U/lanes.slice.d/cap.conf
chown -R $USER_NAME:$USER_NAME $U
systemctl daemon-reload
sudo -u $USER_NAME DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $USER_NAME)/bus systemctl --user daemon-reload

echo "=== VERIFY ==="
systemctl show cloudflared ssh sshd tailscaled -p OOMScoreAdjust 2>/dev/null
systemctl is-active earlyoom
sudo -u $USER_NAME DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $USER_NAME)/bus systemctl --user show laya.slice batch.slice ci.slice lanes.slice -p MemoryMax
