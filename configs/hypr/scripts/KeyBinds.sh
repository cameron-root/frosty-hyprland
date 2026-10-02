#!/usr/bin/env bash
# Advanced Searchable Keybindings & Actions

# Kill previous instances if running
pkill yad 2>/dev/null || true
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Define the config files
keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
laptop_conf="$HOME/.config/hypr/UserConfigs/Laptops.conf"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg="💡 Tip: Type to search by key, description, category, or command. Press [Enter] to run, [Esc] to exit."

files=("$keybinds_conf" "$user_keybinds_conf")
[[ -f "$laptop_conf" ]] && files+=("$laptop_conf")

display_keybinds=$("$HOME/.config/hypr/scripts/keybinds_parser.py" "${files[@]}")

chosen=$(printf '%s\n' "$display_keybinds" | rofi -dmenu -i -matching fuzzy -tokenize -config "$rofi_theme" -mesg "$msg")

if [[ -n "$chosen" ]]; then
    python3 -c '
import sys, json, os, subprocess

chosen = sys.argv[1].strip()
cache_path = "/tmp/hypr_keybinds_exec.json"
if os.path.exists(cache_path):
    with open(cache_path) as f:
        data = json.load(f)
    if chosen in data:
        entry = data[chosen]
        disp = entry.get("dispatcher", "")
        params = entry.get("params", "")
        desc = entry.get("desc", chosen)
        
        # Replace variable tokens if present
        params = params.replace("$term", "kitty").replace("$files", "thunar")
        
        if disp == "exec":
            subprocess.Popen(["bash", "-c", params], start_new_session=True)
            subprocess.run(["notify-send", "-u", "low", "-t", "2000", "⚡ Shortcut Executed", desc])
        elif disp:
            cmd = ["hyprctl", "dispatch", disp]
            if params:
                cmd.append(params)
            subprocess.Popen(cmd, start_new_session=True)
            subprocess.run(["notify-send", "-u", "low", "-t", "2000", "⚡ Action Dispatched", f"{disp} {params}".strip()])
' "$chosen"
fi
