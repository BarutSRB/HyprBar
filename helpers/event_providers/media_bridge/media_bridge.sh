#!/usr/bin/env zsh

# Media Bridge for Spotify
# This script bridges Spotify's playback state to sketchybar's media_change event

PREVIOUS_STATE=""
PREVIOUS_TRACK=""
PREVIOUS_ARTIST=""

while true; do
    # Check if Spotify is running
    if pgrep -f "Spotify" > /dev/null; then
        # Get current state
        PLAYER_STATE=$(osascript -e 'tell application "Spotify" to get player state' 2>/dev/null || echo "stopped")
        
        if [[ "$PLAYER_STATE" == "playing" ]] || [[ "$PLAYER_STATE" == "paused" ]]; then
            # Get track info
            TRACK=$(osascript -e 'tell application "Spotify" to get name of current track' 2>/dev/null || echo "")
            ARTIST=$(osascript -e 'tell application "Spotify" to get artist of current track' 2>/dev/null || echo "")
            ALBUM=$(osascript -e 'tell application "Spotify" to get album of current track' 2>/dev/null || echo "")
            
            # Check if anything changed
            if [[ "$PLAYER_STATE" != "$PREVIOUS_STATE" ]] || [[ "$TRACK" != "$PREVIOUS_TRACK" ]] || [[ "$ARTIST" != "$PREVIOUS_ARTIST" ]]; then
                # Escape quotes for JSON
                TRACK_ESC=$(echo "$TRACK" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
                ARTIST_ESC=$(echo "$ARTIST" | sed 's/"/\\"/g' | sed "s/'/\\'/g") 
                ALBUM_ESC=$(echo "$ALBUM" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
                
                # Create JSON payload
                JSON_INFO="{\"app\":\"Spotify\",\"state\":\"$PLAYER_STATE\",\"title\":\"$TRACK_ESC\",\"artist\":\"$ARTIST_ESC\",\"album\":\"$ALBUM_ESC\"}"
                
                # Trigger media_change event
                sketchybar --trigger media_change INFO="$JSON_INFO"
                
                # Update previous state
                PREVIOUS_STATE="$PLAYER_STATE"
                PREVIOUS_TRACK="$TRACK"
                PREVIOUS_ARTIST="$ARTIST"
            fi
        else
            # Spotify is stopped
            if [[ "$PREVIOUS_STATE" != "stopped" ]]; then
                sketchybar --trigger media_change INFO='{"app":"","state":"stopped","title":"","artist":"","album":""}'
                PREVIOUS_STATE="stopped"
                PREVIOUS_TRACK=""
                PREVIOUS_ARTIST=""
            fi
        fi
    else
        # Spotify not running
        if [[ "$PREVIOUS_STATE" != "" ]]; then
            sketchybar --trigger media_change INFO='{"app":"","state":"stopped","title":"","artist":"","album":""}'
            PREVIOUS_STATE=""
            PREVIOUS_TRACK=""
            PREVIOUS_ARTIST=""
        fi
    fi
    
    # Poll every 2 seconds
    sleep 2
done