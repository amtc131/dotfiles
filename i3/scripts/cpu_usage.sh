#!/usr/bin/env bash
set -euo pipefail

ICON_CPU="${ICON_CPU:-}"
ICON_MEM="${ICON_MEM:-MEM}"
ICON_TMP="${ICON_TMP:-}"
WARN_CPU="${WARN_CPU:-75}"
CRIT_CPU="${CRIT_CPU:-90}"
WARN_MEM="${WARN_MEM:-80}"
CRIT_MEM="${CRIT_MEM:-90}"
WARN_TMP="${WARN_TMP:-75}"
CRIT_TMP="${CRIT_TMP:-85}"

STATE="/tmp/i3blocks_cpu_prev"
read_cpu() { awk '/^cpu /{for(i=2;i<=NF;i++) s+=$i; print s, $5 }' /proc/stat; }
calc_cpu() {
  if [[ -f "$STATE" ]]; then
    read -r prev_total prev_idle < "$STATE" || true
  else
    prev_total=0 prev_idle=0
  fi
  read -r now_total now_idle < <(read_cpu)
  if [[ "$prev_total" -eq 0 ]]; then
    sleep 0.3
    read -r now_total now_idle < <(read_cpu)
    prev_total=$((now_total)) ; prev_idle=$((now_idle))
  fi
  echo "$now_total $now_idle" > "$STATE"
  dt=$((now_total - prev_total))
  di=$((now_idle  - prev_idle))
  cpu=$(( 100 * (dt - di) / (dt==0?1:dt) ))
  echo "$cpu"
}
CPU="$(calc_cpu)"

read -r MEM_TOTAL MEM_AVAIL < <(awk '
  $1=="MemTotal:"{t=$2}
  $1=="MemAvailable:"{a=$2}
  END{print t, a}' /proc/meminfo)
MEM_USED_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / (MEM_TOTAL==0?1:MEM_TOTAL) ))

celsius_from_file() {
  local f="$1" v
  [[ -r "$f" ]] || return 1
  v=$(<"$f") || return 1
  if [[ "$v" =~ ^[0-9]+$ ]] && [ "$v" -gt 200 ]; then
    awk -v t="$v" 'BEGIN{printf "%.0f\n", t/1000}'
  else
    printf "%s\n" "$v"
  fi
}
TEMP=""

while read -r z; do
  t=$(celsius_from_file "$z/temp" 2>/dev/null || true)
  if [[ -n "$t" && "$t" -gt 0 && "$t" -lt 130 ]]; then TEMP="$t"; break; fi
done < <(find /sys/class/thermal -maxdepth 1 -type l -name 'thermal_zone*' 2>/dev/null)

if [[ -z "${TEMP:-}" ]]; then
  for f in /sys/class/hwmon/hwmon*/temp*_input; do
    t=$(celsius_from_file "$f" 2>/dev/null || true)
    if [[ -n "$t" && "$t" -gt 0 && "$t" -lt 130 ]]; then TEMP="$t"; break; fi
  done
fi

if [[ -z "${TEMP:-}" && $(command -v sensors) ]]; then
  TEMP="$(sensors 2>/dev/null | awk '
    /Tdie:|Tctl:|Package id 0:/{
      gsub(/\+|°C|C|,/,"",$2); print int($2); exit
    }
    /Core 0:/{gsub(/\+|°C|C|,/,"",$3); print int($3); exit}
  ')"
fi

color="#cdd6f4"

[[ "$CPU" -ge "$WARN_CPU" ]] && color="#f9e2af"
[[ "$CPU" -ge "$CRIT_CPU" ]] && color="#f38ba8"
[[ "$MEM_USED_PCT" -ge "$WARN_MEM" ]] && color="#f9e2af"
[[ "$MEM_USED_PCT" -ge "$CRIT_MEM" ]] && color="#f38ba8"
if [[ -n "${TEMP:-}" ]]; then
  [[ "$TEMP" -ge "$WARN_TMP" ]] && color="#f9e2af"
  [[ "$TEMP" -ge "$CRIT_TMP" ]] && color="#f38ba8"
fi

if [[ -n "${TEMP:-}" ]]; then
  text="$ICON_CPU ${CPU}%  $ICON_MEM ${MEM_USED_PCT}%  $ICON_TMP ${TEMP}°C"
  short="${CPU}%/${MEM_USED_PCT}%/${TEMP}°C"
else
  text="$ICON_CPU ${CPU}%  $ICON_MEM ${MEM_USED_PCT}%"
  short="${CPU}%/${MEM_USED_PCT}%"
fi

echo "$text"
echo "$short"
echo "$color"

case "${BLOCK_BUTTON:-}" in
  1) ${TERMINAL:-alacritty} -e htop & ;;
esac
