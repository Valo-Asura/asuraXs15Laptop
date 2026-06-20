#!/bin/bash

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || ! command -v hyprctl >/dev/null 2>&1; then
    # Reference dotfiles pill mode is used when no tiled window count is 1.
    # If the shell is previewed outside Hyprland, keep the centered pill layout
    # instead of forcing the full-width bar.
    echo 0
    while true; do sleep 3600; done
fi

update() {
    active_ws=$(hyprctl activeworkspace -j | jq -r .id)
    if [ -z "$active_ws" ] || [ "$active_ws" = "null" ]; then echo 0; return; fi
    hyprctl clients -j | jq -c '[.[] | select(.workspace.id == '"$active_ws"' and .floating == false)] | length'
}

last_val="-1"
do_update() {
    local val=$(update)
    if [ "$val" != "$last_val" ]; then
        echo "$val"
        last_val="$val"
    fi
}

do_update

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    echo "event"
done | while read -r event; do
    while read -t 0.05 -r junk; do true; done
    do_update
done &

while true; do
    sleep 0.5
    do_update
done
