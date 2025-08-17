#!/usr/bin/env zsh

# Enhanced Spotify Display with Album Artwork
# This script displays Spotify info with album artwork and enables popup controls

ARTWORK_CACHE="/tmp/spotify_artwork.jpg"
PREVIOUS_URL=""

# Check if Spotify is running
if ! pgrep -f "Spotify" > /dev/null; then
    sketchybar --set media_cover drawing=off icon.drawing=off
    sketchybar --set media_artist drawing=off
    sketchybar --set media_title drawing=off
    exit 0
fi

# Get Spotify state
PLAYER_STATE=$(osascript -e 'tell application "Spotify" to get player state' 2>/dev/null || echo "stopped")

if [[ "$PLAYER_STATE" == "playing" ]]; then
    # Get track info
    TRACK=$(osascript -e 'tell application "Spotify" to get name of current track' 2>/dev/null || echo "")
    ARTIST=$(osascript -e 'tell application "Spotify" to get artist of current track' 2>/dev/null || echo "")
    ARTWORK_URL=$(osascript -e 'tell application "Spotify" to get artwork url of current track' 2>/dev/null || echo "")
    
    if [[ -n "$TRACK" && -n "$ARTIST" ]]; then
        # Download artwork if URL changed
        if [[ -n "$ARTWORK_URL" && "$ARTWORK_URL" != "$PREVIOUS_URL" ]]; then
            curl -s "$ARTWORK_URL" -o "$ARTWORK_CACHE"
            PREVIOUS_URL="$ARTWORK_URL"
        fi
        
        # Update media display with artwork
        if [[ -f "$ARTWORK_CACHE" ]]; then
            sketchybar --set media_cover drawing=on \
                icon.drawing=on \
                icon.background.image="$ARTWORK_CACHE" \
                icon.background.image.scale=0.11 \
                icon.background.height=30 \
                icon.background.width=30 \
                icon.background.corner_radius=6 \
                icon.background.color=0x00000000
        else
            sketchybar --set media_cover drawing=on \
                icon.drawing=on \
                icon.background.height=30 \
                icon.background.width=30 \
                icon.background.color=0xff333333
        fi
        
        # Update artist and title
        sketchybar --set media_artist drawing=on label="$ARTIST" label.width=dynamic
        sketchybar --set media_title drawing=on label="$TRACK" label.width=dynamic
    else
        sketchybar --set media_cover drawing=off icon.drawing=off
        sketchybar --set media_artist drawing=off
        sketchybar --set media_title drawing=off
    fi
else
    # Not playing - hide items but keep artwork cached
    sketchybar --set media_cover drawing=off icon.drawing=off
    sketchybar --set media_artist drawing=off  
    sketchybar --set media_title drawing=off
fi