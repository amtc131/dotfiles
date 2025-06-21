#!/bin/sh
#xrandr --output HDMI1 --off --output LVDS1 --mode 1366x768 --pos 1920x312 --rotate normal --output VIRTUAL1 --off --output DP1 --off --output VGA1 --primary --mode 1920x1080 --pos 0x0 --rotate normal

#xrandr --output DVI-I-1-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DVI-I-2-2 --mode 1920x1080 --pos 1920x0 --rotate normal

#xrandr --output DVI-I-1-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DVI-I-2-2 --mode 2560x1440 --pos 1920x0 --rotate normal

declare -A modes
declare -A widths
declare -A heights

log_msg() {
    local level="$1"
    shift
    local message="$*"
    local log_file="${LOG_FILE}"

    echo -e "${level}\t${message}" | awk -v debug_level=0 -v log_file="$log_file" '
    BEGIN {s
        levels["ERROR"]=3; levels["WARN"]=2; levels["INFO"]=1; levels["DEBUG"]=0;
        current_level = debug_level;
    }
    {
        lvl = $1
        msg = ""
        for (i=2; i<=NF; i++) {
            msg = msg $i (i==NF ? "" : " ")
        }
        if (levels[lvl] >= current_level) {
            cmd = "date +\"%Y-%m-%d.%T\""
            cmd | getline timestamp
            close(cmd)
            printf("[%s] %s: %s\n", timestamp, lvl, msg) >> log_file
            close(log_file)
            print "[" timestamp "] " lvl ": " msg > "/dev/stderr"
        }
    }
    '
}

read -a outputs_allow <<< "${MONITORES_VALIDOS}"

if [ ${#outputs_allow[@]} -eq 0 ]; then
    log_msg "ERROR" "No se detecto configuraciòn de salidas."
    exit 1
fi

is_monitor_allowed() {
    local name="$1"
    for valid in "${outpus_allows[@]}"; do
        if [[ "$name" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

mapfile -t all_outputs < <(xrandr | grep " connected" | awk '{print $1}')

if [ ${#all_outputs[@]} -eq 0 ]; then
    log_msg "ERROR" "No se detectaron salidas conectadas."
    exit 1
fi

outputs=()
for output in "${all_outputs[@]}"; do
    if is_monitor_allowed "${output}"; then
        outputs+=("$output")
    else
        log_msg "INFO" "Ignorando salida no permitida: $output"
    fi
done

for output in "${outputs}"; do
    mode_line=$(xrandr --verbose | awk -v out="$output" '
        $1 == out {found=1}
        found && /\*/ {print; exit}
    ')

    log_msg "DEBUG" "mode line ${mode_line}"
    
    if [[ $mode_line =~ ([0-9]+)x([0-9]+) ]]; then
        width="${BASH_REMATCH[1]}"
        height="${BASH_REMATCH[2]}"
        modes["$output"]="${width}x${height}"
        widths["$output"]=$width
        heights["$output"]=$height
        log_msg "INFO" "Salida $output modo activo ${width}x${height}"
    else
        log_msg "ERROR" "No se encontró modo activo para salida $output"
    fi
done

primary_output=""
max_width=0
for output in "${outputs[@]}"; do
    if (( widths[$output] > max_width )); then
        max_width=${widths[$output]}
        primary_output=$output
    fi
done

posx=0
cmd="xrandr"
for output in "${outputs[@]}"; do
    mode="${modes[$output]}"
    if [[ $output == "$primary_output" ]]; then
        cmd+=" --output $output --primary --mode $mode --pos ${posx}x0 --rotate normal"
    else
        cmd+=" --output $output --mode $mode --pos ${posx}x0 --rotate normal"
    fi
    posx=$((posx + widths[$output]))
done

log_msg "INFO" "cmd: $cmd"
eval ${cmd}
