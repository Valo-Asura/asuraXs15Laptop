#!/usr/bin/env bash
set -euo pipefail

# ---- HANDLE SCROLL ----
if [ "$1" = "up" ]; then
    hyprctl dispatch workspace e+1 >/dev/null 2>&1
    exit 0
elif [ "$1" = "down" ]; then
    hyprctl dispatch workspace e-1 >/dev/null 2>&1
    exit 0
fi

# ---- GET ACTIVE WORKSPACE ----
ACTIVE=$(hyprctl activeworkspace -j | jq -r '.id // empty')

[ -z "$ACTIVE" ] && exit 0

TEXT="[Workspace $ACTIVE]"
TOOLTIP="Active Workspace: $ACTIVE"

printf '{"text":"%s","tooltip":"%s"}\n' "$TEXT" "$TOOLTIP"
