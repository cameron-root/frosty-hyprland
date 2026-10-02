#!/usr/bin/env bash
# /* ---- 💫 Caelestia Media Controls 💫 ---- */
# Floating frosted glass media popup using playerctl + notify-send

PLAYER=$(playerctl -l 2>/dev/null | head -1)

if [[ -z "$PLAYER" ]]; then
  notify-send "Media" "No media player active" -i audio-x-generic -t 2000
  exit 0
fi

case "$1" in
  play-pause) playerctl play-pause ;;
  next)       playerctl next ;;
  prev)       playerctl previous ;;
  stop)       playerctl stop ;;
  *)
    # Show current track info as notification
    STATUS=$(playerctl status 2>/dev/null)
    TITLE=$(playerctl metadata title 2>/dev/null || echo "Unknown")
    ARTIST=$(playerctl metadata artist 2>/dev/null || echo "Unknown")
    ALBUM=$(playerctl metadata album 2>/dev/null || echo "")
    ICON=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "audio-x-generic")
    
    if [[ "$STATUS" == "Playing" ]]; then
      ICON_STATUS="▶"
    elif [[ "$STATUS" == "Paused" ]]; then
      ICON_STATUS="⏸"
    else
      ICON_STATUS="⏹"
    fi
    
    BODY="$ARTIST"
    [[ -n "$ALBUM" ]] && BODY="$BODY • $ALBUM"
    
    notify-send "$ICON_STATUS $TITLE" "$BODY" \
      -i audio-x-generic \
      -t 3000 \
      -h string:x-canonical-private-synchronous:media-notification
    ;;
esac
