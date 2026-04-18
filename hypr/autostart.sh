#!/bin/bash
# ~/.config/hypr/autostart.sh
# Launches apps and moves them to the correct workspace once their window appears.
# Use in hyprland.conf:
#   exec-once = ~/.config/hypr/autostart.sh

# ── helpers ───────────────────────────────────────────────────────────────────

# Wait for a window matching a class/title regex, then move it to a workspace.
# Usage: launch_on <workspace> <class_regex> <command>
launch_on() {
    local ws="$1"
    local class="$2"
    shift 2
    local cmd=("$@")

    # Launch the app in the background
    "${cmd[@]}" &

    # Poll until the window appears, then move it
    for _ in $(seq 1 30); do
        sleep 1
        local addr
        addr=$(hyprctl clients -j \
            | grep -i "\"class\": \"$class\"" \
            | head -1)
        if [[ -n "$addr" ]]; then
            hyprctl dispatch movetoworkspacesilent "$ws,class:^(${class})$"
            break
        fi
    done
}

# ── app definitions ───────────────────────────────────────────────────────────
#   launch_on <workspace> <window class> <command ...>

launch_on 1 firefox          firefox
launch_on 2 code             code
launch_on 3 kitty            kitty
launch_on 4 vesktop          vesktop
launch_on 5 steam            steam
launch_on 6 spotify          spotify