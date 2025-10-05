#!/bin/bash

bar_color="#7f7fff"
volume_step=1
brightness_step=2.5
max_volume=100

function get_volume {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

function get_mute {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(?<=Mute: )(yes|no)'
}

function get_brightness {
    xbacklight | grep -Po '[0-9]{1,3}' | head -n 1
}

function get_volume_icon {
    volume=$(get_volume)
    mute=$(get_mute)
    if [ "$volume" -eq 0 ] || [ "$mute" == "yes" ] ; then
        volume_icon=""
    elif [ "$volume" -lt 50 ]; then
        volume_icon=""
    else
        volume_icon=""
    fi
}

function get_brightness_icon {
    brightness_icon=""
}

function show_volume_notif {
    volume=$(get_mute)
    get_volume_icon
    dunstify -i audio-volume-muted-blocking -t 1000 -r 2593 -u normal "$volume_icon $volume%" -h int:value:$volume -h string:hlcolor:$bar_color
}

function show_brightness_notif {
    brightness=$(get_brightness)
    get_brightness_icon
    dunstify -t 1000 -r 2593 -u normal "$brightness_icon $brightness%" -h int:value:$brightness -h string:hlcolor:$bar_color
}

case $1 in
    volume_up)
    pactl set-sink-mute @DEFAULT_SINK@ 0
    volume=$(get_volume)
    if [ $(( "$volume" + "$volume_step" )) -gt $max_volume ]; then
        pactl set-sink-volume @DEFAULT_SINK@ $max_volume%
    else
        pactl set-sink-volume @DEFAULT_SINK@ +$volume_step%
    fi
    show_volume_notif
    ;;

    volume_down)
    pactl set-sink-volume @DEFAULT_SINK@ -$volume_step%
    show_volume_notif
    ;;

    volume_mute)
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    show_volume_notif
    ;;

    brightness_up)
    xbacklight -inc $brightness_step -time 0 
    show_brightness_notif
    ;;

    brightness_down)
    xbacklight -dec $brightness_step -time 0
    show_brightness_notif
    ;;
esac
