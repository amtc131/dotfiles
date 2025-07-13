#!/bin/bash
tmp_img="/tmp/flameshot_$(date +%s).png"
flameshot gui -p "$tmp_img"
xclip -selection clipboard -t image/png -i "$tmp_img"

