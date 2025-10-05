#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Imagenes/wallpapers"

img=(`find $WALLPAPER_DIR/ -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image' | cut -d':' -f1`)
while true
do
   feh --bg-scale "${img[$RANDOM % ${#img[@]} ]}"
sleep 30m
done

#feh --randomize --bg-fill "$WALLPAPER_DIR"/*
