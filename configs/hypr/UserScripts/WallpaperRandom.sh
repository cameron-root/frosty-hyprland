#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Script for Random Wallpaper ( CTRL ALT W)
export PATH="$HOME/.local/bin:$PATH"

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$focused_monitor" ]]; then
  focused_monitor="eDP-1"
fi

mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.webp" \) -print0)

if [ ${#PICS[@]} -eq 0 ]; then
  exit 0
fi

RANDOMPICS="${PICS[$((RANDOM % ${#PICS[@]}))]}"

# Ensure hyprpaper service is active
if ! systemctl --user is-active --quiet hyprpaper; then
  systemctl --user start hyprpaper
  sleep 0.3
fi

# Persist for next boot / restart
cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor = $focused_monitor
    path = $RANDOMPICS
}

splash = false
ipc = on
EOF


# Apply wallpaper immediately — swww wipe transition (iOS glass feel)
if command -v swww &>/dev/null; then
  swww img -o "$focused_monitor" "$RANDOMPICS" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 1.5 \
    --transition-fps 60
else
  hyprctl hyprpaper wallpaper "$focused_monitor,$RANDOMPICS" 2>/dev/null || true
fi

# Update state tracking for JaKooLit and Rofi
mkdir -p "$HOME/.config/hypr/wallpaper_effects"
echo "$RANDOMPICS" > "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
mkdir -p "$HOME/.config/rofi"
ln -sf "$RANDOMPICS" "$HOME/.config/rofi/.current_wallpaper" 2>/dev/null || true

# Run additional scripts — regenerate wallust colors
"$SCRIPTSDIR/WallustSwww.sh" "$RANDOMPICS"
sleep 1
"$SCRIPTSDIR/Refresh.sh"

# Notify user
notify-send "Wallpaper Changed" "Colors regenerated" -t 2000 &

