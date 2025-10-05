#!/usr/bin/env bash
set -euo pipefail
set -x

TARGET_SCRIPT="$HOME/.config/dotfiles/.screenlayout/home-setup-spartan.sh"
STATE_FILE="$HOME/.cache/monitores_prev.txt"
mkdir -p "$(dirname "$STATE_FILE")"

mapfile -t outputs < <(xrandr --query | awk '$2=="connected"{print $1}')

if (( ${#outputs[@]} == 0 )); then
  notify-send "Monitores" "No se detectaron salidas conectadas." || true
  exit 1
fi

declare -A preselected=()

if [[ -n "${MONITORES_VALIDOS:-}" ]]; then
  for m in $MONITORES_VALIDOS; do preselected["$m"]=1; done
# 2b) Si no, cargar última selección guardada
elif [[ -f "$STATE_FILE" ]]; then
  while read -r m; do
    [[ -n "$m" ]] && preselected["$m"]=1
  done < "$STATE_FILE"
fi

args=()
for o in "${outputs[@]}"; do
  if [[ -n "${preselected[$o]:-}" ]]; then
    args+=("TRUE" "$o")
  else
    args+=("FALSE" "$o")
  fi
done

sel="$(zenity --list --checklist \
      --title='Monitores' \
      --text='Selecciona las salidas (puedes marcar varias)' \
      --column='Usar' --column='Salida' \
      --separator=' ' \
      "${args[@]}" )" || exit 0

MONITORES_VALIDOS="$(echo -n "$sel")"

: > "$STATE_FILE"
for m in $MONITORES_VALIDOS; do
  echo "$m" >> "$STATE_FILE"
done

i3-msg -q "exec --no-startup-id bash -lc 'MONITORES_VALIDOS=\"${MONITORES_VALIDOS}\" . \"${TARGET_SCRIPT}\"'"
