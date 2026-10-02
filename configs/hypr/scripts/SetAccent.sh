#!/usr/bin/env bash
# ==============================================================================
# Caelestia & Hyprland - Multi-Accent Color Switcher
# Supports: Blue, Red, Green, Grey, Purple, Amber
# ==============================================================================

set -euo pipefail

STATE_FILE="$HOME/.local/state/accent.txt"
mkdir -p "$(dirname "$STATE_FILE")"

CURRENT_ACCENT="blue"
if [ -f "$STATE_FILE" ]; then
    CURRENT_ACCENT="$(cat "$STATE_FILE")"
fi

TARGET="${1:-menu}"

# Handle menu mode via rofi
if [ "$TARGET" = "menu" ]; then
    CHOICE=$(printf "🔵 Electric Blue\n🔴 Crimson Red\n🟢 Emerald Green\n⚪ Frosted Grey\n🟣 Liquid Purple\n🟡 Solar Amber" | rofi -dmenu -i -p " Accent Color" -theme-str '
        window { width: 340px; border-radius: 18px; border: 1px solid rgba(255,255,255,0.18); background-color: rgba(13,16,24,0.88); padding: 14px; }
        listview { lines: 6; columns: 1; spacing: 6px; }
        element { border-radius: 12px; padding: 10px 14px; }
        element selected { background-color: rgba(255,255,255,0.14); text-color: #ffffff; }
    ' 2>/dev/null || true)

    if [[ "$CHOICE" == *"Blue"* ]]; then
        TARGET="blue"
    elif [[ "$CHOICE" == *"Red"* ]]; then
        TARGET="red"
    elif [[ "$CHOICE" == *"Green"* ]]; then
        TARGET="green"
    elif [[ "$CHOICE" == *"Grey"* ]]; then
        TARGET="grey"
    elif [[ "$CHOICE" == *"Purple"* ]]; then
        TARGET="purple"
    elif [[ "$CHOICE" == *"Amber"* ]]; then
        TARGET="amber"
    else
        exit 0
    fi
fi

# Handle toggle mode (cycles through blue -> red -> green -> grey -> purple -> amber)
if [ "$TARGET" = "toggle" ]; then
    case "$CURRENT_ACCENT" in
        blue) TARGET="red" ;;
        red) TARGET="green" ;;
        green) TARGET="grey" ;;
        grey) TARGET="purple" ;;
        purple) TARGET="amber" ;;
        *) TARGET="blue" ;;
    esac
fi

echo "Switching global accent to: $TARGET"

# Configure color palettes
case "$TARGET" in
    blue)
        HEX="#388bfd"
        HEX_LIGHT="#58a6ff"
        RGB="rgb(388bfd)"
        BORDER="rgba(388bfdee) rgba(58a6ff66) 45deg"
        LABEL="Electric Blue"
        CAVA_1="#388bfd"
        CAVA_2="#58a6ff"
        CAVA_3="#9A5BDD"
        ;;
    red)
        HEX="#ff3b30"
        HEX_LIGHT="#ff5f56"
        RGB="rgb(ff3b30)"
        BORDER="rgba(ff3b30ee) rgba(ff5f5666) 45deg"
        LABEL="Crimson Red"
        CAVA_1="#ff3b30"
        CAVA_2="#ff5f56"
        CAVA_3="#febc2e"
        ;;
    green)
        HEX="#28c840"
        HEX_LIGHT="#56d4c0"
        RGB="rgb(28c840)"
        BORDER="rgba(40,200,64,0.93) rgba(86,212,192,0.45) 45deg"
        LABEL="Emerald Green"
        CAVA_1="#28c840"
        CAVA_2="#56d4c0"
        CAVA_3="#79c0ff"
        ;;
    grey)
        HEX="#cdd6f4"
        HEX_LIGHT="#f0f6fc"
        RGB="rgb(cdd6f4)"
        BORDER="rgba(240,246,252,0.85) rgba(139,148,158,0.40) 45deg"
        LABEL="Frosted Grey"
        CAVA_1="#cdd6f4"
        CAVA_2="#a5b3c7"
        CAVA_3="#8b949e"
        ;;
    purple)
        HEX="#9a5bdd"
        HEX_LIGHT="#bc8cff"
        RGB="rgb(9a5bdd)"
        BORDER="rgba(154,91,221,0.93) rgba(188,140,255,0.45) 45deg"
        LABEL="Liquid Purple"
        CAVA_1="#9a5bdd"
        CAVA_2="#bc8cff"
        CAVA_3="#58a6ff"
        ;;
    amber)
        HEX="#febc2e"
        HEX_LIGHT="#ffdcc2"
        RGB="rgb(febc2e)"
        BORDER="rgba(254,188,46,0.93) rgba(255,158,59,0.45) 45deg"
        LABEL="Solar Amber"
        CAVA_1="#febc2e"
        CAVA_2="#ff9e3b"
        CAVA_3="#ff5f56"
        ;;
    *)
        echo "Unknown accent: $TARGET"
        exit 1
        ;;
esac

# ── 1. Hyprland Accent Config ─────────────────────────
cat << EOF > "$HOME/.config/hypr/UserConfigs/Accent.conf"
# Dynamic System Accent Configuration ($LABEL)
\$accent_name = $TARGET
\$accent_col = $RGB
\$accent_active = $BORDER
\$accent_glow = rgba(ffffff40)
EOF
hyprctl keyword general:col.active_border "$BORDER" 2>/dev/null || true

# ── 2. Caelestia Shell Scheme ─────────────────────────
caelestia scheme "frosty-$TARGET" 2>/dev/null || true

# ── 3. GTK 3 & 4 Accent CSS ───────────────────────────
cat << EOF > "$HOME/.config/gtk-3.0/accent.css"
/* Dynamic Accent Colors ($LABEL) */
@define-color accent_color $HEX;
@define-color accent_bg_color $HEX;
@define-color accent_fg_color #ffffff;
@define-color accent_selection alpha(@accent_color, 0.35);
@define-color accent_focus alpha(@accent_color, 0.50);
EOF
cp -f "$HOME/.config/gtk-3.0/accent.css" "$HOME/.config/gtk-4.0/accent.css"

# ── 4. Kitty Terminal Accent ──────────────────────────
cat << EOF > "$HOME/.config/kitty/kitty-themes/accent.conf"
# Dynamic Accent for Kitty ($LABEL)
active_tab_foreground     $HEX
active_tab_background     #1a2234
cursor                    $HEX_LIGHT
selection_background      #25334d
EOF
pkill -SIGUSR1 kitty 2>/dev/null || true

# ── 5. Cava Audio Visualizer ──────────────────────────
sed -i "s/gradient_color_1 = .*/gradient_color_1 = '$CAVA_1'/" "$HOME/.config/cava/config" 2>/dev/null || true
sed -i "s/gradient_color_2 = .*/gradient_color_2 = '$CAVA_2'/" "$HOME/.config/cava/config" 2>/dev/null || true
sed -i "s/gradient_color_3 = .*/gradient_color_3 = '$CAVA_3'/" "$HOME/.config/cava/config" 2>/dev/null || true
sed -i "s/foreground = .*/foreground = '$HEX'/" "$HOME/.config/cava/config" 2>/dev/null || true

# ── 6. State & Toast ──────────────────────────────────
echo "$TARGET" > "$STATE_FILE"
caelestia toast success "Accent Changed" "Switched to $LABEL" palette 2>/dev/null || true

echo "Accent '$TARGET' successfully applied!"
