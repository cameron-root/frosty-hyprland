#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Ensure weather cache is up-to-date before locking (Waybar/lockscreen readers)
bash "$HOME/.config/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1

# Notify logind session
loginctl lock-session >/dev/null 2>&1 &

# Direct instant lock via hyprlock
pidof hyprlock || exec hyprlock -q

