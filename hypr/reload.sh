#!/usr/bin/env bash

killall -SIGUSR2 waybar 2>/dev/null

pkill hyprpaper 2>/dev/null
setsid hyprpaper &>/dev/null &

pkill -f wallpaper-cycle.sh 2>/dev/null
setsid ~/.config/hypr/wallpaper-cycle.sh &>/dev/null &

hyprctl reload