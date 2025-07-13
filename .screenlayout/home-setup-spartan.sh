#!/bin/sh
#xrandr --output HDMI1 --off --output LVDS1 --mode 1366x768 --pos 1920x312 --rotate normal --output VIRTUAL1 --off --output DP1 --off --output VGA1 --primary --mode 1920x1080 --pos 0x0 --rotate normal

#xrandr --output DVI-I-1-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DVI-I-2-2 --mode 1920x1080 --pos 1920x0 --rotate normal

#xrandr --output DVI-I-1-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DVI-I-2-2 --mode 2560x1440 --pos 1920x0 --rotate normal

declare -A modes
declare -A widths
declare -A heights
debug_level="${DEBUG_LEVEL:-1}"
cmd="xrandr"

log_msg() {
    local level="$1"
    shift
    local message="$*"
    local log_file="${LOG_FILE}"

    if [[ -z "$log_file" ]]; then
        echo "[$(date +'%Y-%m-%d.%T')] $level: $message" >&2
        return
    fi

    echo -e "${level}\t${message}" | awk -v debug_level="'$debug_level'" -v log_file="$log_file" '
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

log_msg "DEBUG" "variable MONITORES_VALIDOS= ${MONITORES_VALIDOS}"
read -a outputs_allow <<< "${MONITORES_VALIDOS}"

log_msg "DEBUG" "outputs_allow: ${outputs_allow[*]}"

if [ ${#outputs_allow[@]} -eq 0 ]; then
    log_msg "ERROR" "No se detectó configuración de salidas permitidas."
    exit 1
fi

is_monitor_allowed() {
    local name="$1"
    for valid in "${outputs_allow[@]}"; do
        #log_msg "DEBUG" "Valid ${valid}"
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
        log_msg "INFO" "Ignorando salida no permitida: [$output]"
        cmd+=" --output $output --off"
    fi
done

if [ ${#outputs[@]} -eq 0 ]; then
    log_msg "ERROR" "No se detectaron salidas válidas conectadas.."
    exit 1
fi

for output in "${outputs[@]}"; do
   mode_line=$(xrandr | grep "^${output} connected" -A20 | grep '\*' | head -n1)

   if [[ -z "$mode_line" ]]; then
       mode_line=$(xrandr | grep "^${output} connected" -A20 | grep '+' | head -n1)
   fi

    log_msg "DEBUG" "mode line ${mode_line} for output ${output}"
   if [[ -z "$mode_line" ]]; then
       mode="1920x1080"
       log_msg "WARN" "No se encontró modo activo ni preferido para salida $output. Usando modo por defecto: $mode"
       modes["$output"]=$mode
       widths["$output"]=1920
       heights["$output"]=1080
   else
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
   fi
done

sorted_outputs=($(for out in "${outputs[@]}"; do
                      echo "$out ${widths[$out]}"
                done | sort -nk2 | awk '{print $1}'))

primary_output="${sorted_outputs[-1]}"
log_msg "DEBUG" "primary outputs ${primary_output}"

posx=0
for output in "${sorted_outputs[@]}"; do
    mode="${modes[$output]}"
    if [[ -z "$mode" ]]; then
        log_msg "WARN" "Saltando salida sin modo válido: $output"
        continue
    fi

     args="--output $output --mode $mode --pos ${posx}x0 --rotate normal"
    [[ $output == "$primary_output" ]] && args+=" --primary"
       #cmd+=" --output $output --primary --mode $mode --pos ${posx}x0 --rotate normal"
    cmd+=" $args"
    #else
        #cmd+=" --output $output --mode $mode --pos ${posx}x0 --rotate normal"
    #fi

    posx=$((posx + widths[$output]))
done

log_msg "INFO" "cmd: $cmd"
eval ${cmd}
