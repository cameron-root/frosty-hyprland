#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000
step=10  # INCREASE/DECREASE BY THIS VALUE

# Get current brightness as an integer (without %)
get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

# Determine the icon based on brightness level
get_icon_path() {
    local brightness=$1
    local level=$(( (brightness + 19) / 20 * 20 ))  # Round up to next 20
    if (( level > 100 )); then
        level=100
    fi
    echo "$iDIR/brightness-${level}.png"
}

# Send notification (disabled: Caelestia handles OSD natively)
send_notification() {
    return 0
}

# Change brightness and trigger Caelestia OSD
change_brightness() {
    local delta=$1
    if [[ "$delta" -gt 0 ]]; then
        brightnessctl set "${delta}%+" >/dev/null 2>&1
        qs -c caelestia ipc call brightness set "+${delta}%" >/dev/null 2>&1 || true
    else
        local abs_delta=$(( -delta ))
        brightnessctl set "${abs_delta}%-" >/dev/null 2>&1
        qs -c caelestia ipc call brightness set "${abs_delta}%-" >/dev/null 2>&1 || true
    fi
}

# Main
case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    *)
        get_brightness
        ;;
esac