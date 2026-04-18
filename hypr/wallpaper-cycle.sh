#!/usr/bin/env bash

DAY_HOUR=7
NIGHT_HOUR=20

DAY_WALL="$HOME/.config/hypr/paper/day.jpg"
NIGHT_WALL="$HOME/.config/hypr/paper/night.jpg"

apply_day() {
    hyprctl hyprpaper wallpaper "DP-2,$DAY_WALL" &>/dev/null
    hyprctl hyprpaper wallpaper "HDMI-A-1,$DAY_WALL" &>/dev/null
}
apply_night() {
    hyprctl hyprpaper wallpaper "DP-2,$NIGHT_WALL" &>/dev/null
    hyprctl hyprpaper wallpaper "HDMI-A-1,$NIGHT_WALL" &>/dev/null
}

apply_now() {
    hour=$(date +%H)
    if (( hour >= DAY_HOUR && hour < NIGHT_HOUR )); then
        apply_night
        echo "night"
    else
        apply_day
        echo "day"
    fi
}

# --- FAST START ---
current_mode=$(apply_now)

# If hyprpaper wasn't ready yet, retry once shortly after
sleep 0.5
current_mode=$(apply_now)

# --- MAIN LOOP ---
while true; do
    hour=$(date +%H)

    if (( hour >= DAY_HOUR && hour < NIGHT_HOUR )); then
        [[ "$current_mode" != "day" ]] && current_mode=$(apply_now)
    else
        [[ "$current_mode" != "night" ]] && current_mode=$(apply_now)
    fi

    # sleep until next minute boundary (feels instant at change)
    sleep $((60 - $(date +%S)))
done