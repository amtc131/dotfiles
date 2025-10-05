#!/usr/bin/env bash
set -euo pipefail

MOUNTPOINT="${MOUNTPOINT:-/}"  
WARN="${WARN:-80}"             
CRIT="${CRIT:-90}"            

read -r fs size used avail usep mount <<<"$(df -hP "$MOUNTPOINT" | awk 'NR==2{print $1,$2,$3,$4,$5,$6}')"
use="${usep%\%}"

text="$MOUNTPOINT $used/$size ($avail libres)"
short="$usep"

color="#cdd6f4"
[ "$use" -ge "$WARN" ] && color="#f9e2af"
[ "$use" -ge "$CRIT" ] && color="#f38ba8"

echo "$text"
echo "$short"
echo "$color"

case "${BLOCK_BUTTON:-}" in
  1) ${TERMINAL:-alacritty} -e bash -lc "df -h; echo; ls -lah \"$MOUNTPOINT\" | head -n 50; read -n1 -s -r -p 'Cerrar...'" & ;;
esac
