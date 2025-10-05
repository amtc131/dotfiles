#!/usr/bin/env bash

ROFI_TEXT="System:"
ASK_CONFIRM=false 

LOCK_CMD="i3lock"

command -v rofi >/dev/null 2>&1 || { echo "rofi no encontrado"; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "systemd no encontrado"; exit 1; }

declare -A MENU=(
  ["  Shutdown"]="systemctl poweroff"
  ["  Reboot"]="systemctl reboot"
  ["  Suspend"]="systemctl suspend"
  ["  Hibernate"]="systemctl hibernate"
  ["  Lock"]="$LOCK_CMD"
  ["  Logout"]="i3-msg exit"
  ["  Cancel"]=""
)

selection="$(printf '%s\n' "${!MENU[@]}" | sort | rofi -dmenu -i -p "$ROFI_TEXT" ${ROFI_THEME:+-theme "$ROFI_THEME"})"

[[ -z "$selection" ]] && exit 0

cmd="${MENU[$selection]}"

needs_confirm_regex="Shutdown|Reboot|Hibernate|Suspend|Logout"
if $ASK_CONFIRM || [[ "$selection" =~ $needs_confirm_regex ]]; then
  confirm="$(printf 'Yes\nNo' | rofi -dmenu -i -p "${selection}?")"
  [[ "$confirm" != "Yes" ]] && exit 0
fi

if [[ -n "$cmd" ]]; then
  i3-msg -q "exec --no-startup-id $cmd"
fi
