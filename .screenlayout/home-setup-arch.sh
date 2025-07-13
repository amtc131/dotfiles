#!/bin/bash

manifest="$HOME/.config/dotfiles/.screenlayout/MANIFEST.linux"

declare -A config
declare -A modes
declare -A positions
declare -A active_outputs

current_section=""
while IFS='=' read -r key value; do
    [[ "$key" =~ ^\[[a-zA-Z0-9]+\]$ ]] && {
        current_section="${key//[\[\]]/}"
        continue
    }
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    config["$current_section.$key"]="$value"
done < "$manifest"

mapfile -t connected_outputs < <(xrandr | grep " connected" | awk '{print $1}')

is_output_connected() {
    local output="$1"
    for connected in "${connected_outputs[@]}"; do
        [[ "$connected" == "$output" ]] && return 0
    done
    return 1
}

left_output=""
right_output=""
primary_output=""
cmd=""

for section in monitor1 monitor2; do
    output="${config[$section.output]}"
    mode="${config[$section.mode]}"
    primary="${config[$section.primary]}"
    position="${config[$section.position]}"

    echo "[DEBUG] monitor $output"
    if is_output_connected "$output"; then
        modes["$output"]="$mode"
        positions["$position"]="$output"
        [[ "$primary" == "true" ]] && primary_output="$output"
        active_outputs["$output"]=1
    else
        echo "[INFO] Monitor $output no está conectado. Se desactivará."
        cmd+=" --output $output --off"
    fi
done

for key in "${!config[@]}"; do
    echo "[DEBUG] $key = ${config[$key]}"
done


disabled_outputs="${config[disabled.outputs]}"
echo "[DEBUG] disable $disabled_outputs"
if [[ -n "$disabled_outputs" ]]; then
    for out in $disabled_outputs; do
        if is_output_connected "$out"; then
            echo "[INFO] Desactivando salida deshabilitada: $out"
            cmd+=" --output $out --off"
        fi
    done
fi

if [[ -n "${positions[left]}" && -n "${positions[right]}" ]]; then
    left="${positions[left]}"
    right="${positions[right]}"
    left_width="${modes[$left]%%x*}"

    cmd+=" --output $left --mode ${modes[$left]} --pos 0x0 --rotate normal"
    cmd+=" --output $right --mode ${modes[$right]} --pos ${left_width}x0 --rotate normal"
    
    [[ "$right" == "$primary_output" ]] && cmd+=" --primary"
elif [[ -n "${positions[left]}" ]]; then
    left="${positions[left]}"
    cmd+=" --output $left --mode ${modes[$left]} --pos 0x0 --rotate normal"
    [[ "$left" == "$primary_output" ]] && cmd+=" --primary"
elif [[ -n "${positions[right]}" ]]; then
    right="${positions[right]}"
    cmd+=" --output $right --mode ${modes[$right]} --pos 0x0 --rotate normal"
    [[ "$right" == "$primary_output" ]] && cmd+=" --primary"
fi

echo "[INFO] Ejecutando: xrandr $cmd"
# xrandr $cmd
