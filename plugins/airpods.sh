#!/bin/bash

# Get AirPods data from Bluetooth system profiler
BLUETOOTH_DATA=$(system_profiler SPBluetoothDataType 2>/dev/null)

# Check if any AirPods are connected
CONNECTED_AIRPODS=$(echo "$BLUETOOTH_DATA" | awk '/Connected:/{flag=1} flag && /AirPods/{found=1} found && /Address:/{print; exit}')

if [ -z "$CONNECTED_AIRPODS" ]; then
    echo "Not connected"
    exit 0
fi

# Get the connected AirPods section
AIRPODS_SECTION=$(echo "$BLUETOOTH_DATA" | awk '/Connected:/,/Not Connected:/' | awk '/AirPods/,/^      [^ ]/')

# Extract battery levels
LEFT_BATTERY=$(echo "$AIRPODS_SECTION" | grep -o "Left Battery Level: [0-9]*" | grep -o "[0-9]*" | head -1)
RIGHT_BATTERY=$(echo "$AIRPODS_SECTION" | grep -o "Right Battery Level: [0-9]*" | grep -o "[0-9]*" | head -1)

# If battery levels aren't found in the standard fields, try alternate methods
if [ -z "$LEFT_BATTERY" ] && [ -z "$RIGHT_BATTERY" ]; then
    # Try to get battery from ioreg
    IOREG_DATA=$(ioreg -r -c AppleDeviceManagementHIDEventService 2>/dev/null | grep -E '"BatteryPercent"|"Product"' | grep -B1 "AirPods" | grep "BatteryPercent" | head -2)
    
    if [ -n "$IOREG_DATA" ]; then
        # Parse ioreg data
        BATTERIES=($(echo "$IOREG_DATA" | grep -o "[0-9]*"))
        if [ ${#BATTERIES[@]} -ge 1 ]; then
            LEFT_BATTERY=${BATTERIES[0]}
        fi
        if [ ${#BATTERIES[@]} -ge 2 ]; then
            RIGHT_BATTERY=${BATTERIES[1]}
        fi
    fi
fi

# If we still don't have battery info, show connected status
if [ -z "$LEFT_BATTERY" ] && [ -z "$RIGHT_BATTERY" ]; then
    echo "􀪷|Connected|Battery info unavailable"
    exit 0
fi

# Calculate minimum battery for main display
MIN_BATTERY=100
if [ -n "$LEFT_BATTERY" ]; then
    MIN_BATTERY=$LEFT_BATTERY
fi
if [ -n "$RIGHT_BATTERY" ] && [ "$RIGHT_BATTERY" -lt "$MIN_BATTERY" ]; then
    MIN_BATTERY=$RIGHT_BATTERY
fi

# AirPods icon
ICON="􀪷"

# Build details string for popup (L:X% R:Y%)
DETAILS=""
if [ -n "$LEFT_BATTERY" ]; then
    DETAILS="L:${LEFT_BATTERY}%"
fi
if [ -n "$RIGHT_BATTERY" ]; then
    if [ -n "$DETAILS" ]; then
        DETAILS="$DETAILS R:${RIGHT_BATTERY}%"
    else
        DETAILS="R:${RIGHT_BATTERY}%"
    fi
fi

# Output format: icon|label|details
echo "${ICON}|${MIN_BATTERY}%|${DETAILS}"