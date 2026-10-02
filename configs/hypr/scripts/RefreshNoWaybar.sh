#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Modified version of Refresh.sh but waybar wont refresh
# Used by automatic wallpaper change
# Modified inorder to refresh rofi background, Wallust, SwayNC only

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Kill already running processes
_ps=(rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# quit ags & relaunch ags
#ags -q && ags &

# Ensure caelestia-shell stays running
if ! systemctl --user is-active --quiet caelestia-shell.service; then
    systemctl --user start caelestia-shell.service 2>/dev/null || true
fi

# Wallust refresh (synchronous to ensure colors are ready)
${SCRIPTSDIR}/WallustSwww.sh
sleep 0.2

# Re-apply current accent color so border and theme stay synced
${SCRIPTSDIR}/SetAccent.sh "$(cat ~/.local/state/accent.txt 2>/dev/null || echo "blue")" >/dev/null 2>&1 &


exit 0