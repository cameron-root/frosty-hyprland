#!/usr/bin/env bash
# /* ---- 💫 Caelestia iOS Glass — Clipboard Manager 💫 ---- */
# Pipes cliphist entries through iOS glass rofi picker, decodes and copies selection

export PATH="$HOME/.local/bin:$PATH"

cliphist list | rofi -dmenu -p " Clipboard" \
  -theme ~/.config/rofi/config-clipboard.rasi \
  -display-columns 2 | cliphist decode | wl-copy
