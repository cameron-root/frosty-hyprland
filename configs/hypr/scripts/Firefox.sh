#!/usr/bin/env bash
# /* ---- 💫 Caelestia Firefox Launcher 💫 ---- */
# Launches Firefox with the Caelestia iOS Frosted Glass profile

PROFILE="$HOME/.mozilla/firefox/profile.default"

# Clean up any stale lock files
rm -f "$PROFILE/.parentlock"

# Launch Firefox with the Caelestia profile
exec firefox --profile "$PROFILE" "$@"
