#!/bin/bash

manifest="$HOME/.config/dotfiles/.screenlayout/MANIFEST.linux"

declare -A config

current_section=""
while IFS='=' read -r key value; do
    [[ "$key" =~ ^\[[a-zA-Z0-9]+\]$ ]] && {
        current_section="${key//[\[\]]/}"
        continue
    }
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    config["$current_section.$key"]="$value"
done < "$manifest"

left_output=""
right_output=""
primary_output=""
declare -A modes
declare -A positions

for section in monitor1 monitor2; do
    output="${config[$section.output]}"
    mode="${config[$section.mode]}"
    primary="${config[$section.primary]}"
    position="${config[$section.position]}"

    modes["$output"]="$mode"
    positions["$position"]="$output"

    [[ "$primary" == "true" ]] && primary_output="$output"
done

left="${positions[left]}"
right="${positions[right]}"
left_width="${modes[$left]%%x*}"

cmd="xrandr --output $left --mode ${modes[$left]} --pos 0x0 --rotate normal"
cmd+=" --output $right --mode ${modes[$right]} --pos ${left_width}x0 --rotate normal"

[[ "$right" == "$primary_output" ]] && cmd+=" --primary"

echo "[INFO] Ejecutando: $cmd"
eval "$cmd"
