#!/bin/bash

# ==============================================================================
# Script Name: focus_monitor.sh
# Description: A background service that monitors the GNOME panel clock format.
#              If a "Focus:" message is not present for a set duration
#              between specified hours, it locks the screen.
#
# Author:      Gemini, for the user
# Version:     1.0
# Date:        September 4, 2025
# ==============================================================================

# --- Configuration ---
# This MUST match the key in your focus.sh script
DCONF_KEY="/org/gnome/shell/extensions/panel-date-format/format"

# Lock the screen after being unfocused for this many seconds (10 minutes = 600 seconds)
LOCK_THRESHOLD_SECONDS=600

# How often to check the status, in seconds
CHECK_INTERVAL_SECONDS=60

# --- State Variable ---
# Stores the Unix timestamp of when the "unfocused" state began. 0 means focused.
UNFOCUSED_START_TIME=0

echo "Focus Monitor starting. Will lock screen after $LOCK_THRESHOLD_SECONDS seconds of no focus between 7 PM and 9 AM."

# --- Main Loop ---
while true; do
    # Get the current hour in 24-hour format (e.g., 19 for 7 PM)
    current_hour=$(date +%H)

    # Check if the current time is within the active monitoring window (7 PM to 9 AM)
    # This means the hour is 19 or greater, OR less than 9.
    if [[ "$current_hour" -ge 19 || "$current_hour" -lt 9 ]]; then
        # We are INSIDE the monitoring window.
        
        # Read the current format from dconf
        current_format=$(dconf read "$DCONF_KEY")

        # Check if the format string contains our focus keyword
        if [[ "$current_format" == *"Focus:"* ]]; then
            # Focus IS set. Reset the unfocused timer.
            if [[ "$UNFOCUSED_START_TIME" -ne 0 ]]; then
                echo "[$(date +'%T')] Focus has been set. Countdown cancelled."
                UNFOCUSED_START_TIME=0
            fi
        else
            # Focus IS NOT set. Start or check the countdown.
            if [[ "$UNFOCUSED_START_TIME" -eq 0 ]]; then
                # This is the first time we've noticed the lack of focus. Start the timer.
                UNFOCUSED_START_TIME=$(date +%s)
                echo "[$(date +'%T')] No focus set. Starting 10-minute lock countdown."
            else
                # Timer is already running. Check if it has expired.
                current_time=$(date +%s)
                elapsed_seconds=$((current_time - UNFOCUSED_START_TIME))

                if [[ "$elapsed_seconds" -gt "$LOCK_THRESHOLD_SECONDS" ]]; then
                    echo "[$(date +'%T')] Unfocused for over 10 minutes. Locking screen!"
                    # Use a generic command to lock the screen
                    xdg-screensaver lock
                    # Reset the timer to prevent instant re-locking after unlocking
                    UNFOCUSED_START_TIME=0
                # else # Optional: for debugging
                    # remaining=$((LOCK_THRESHOLD_SECONDS - elapsed_seconds))
                    # echo "[$(date +'%T')] Unfocused. Time to lock: $remaining seconds."
                fi
            fi
        fi
    else
        # We are OUTSIDE the monitoring window. Ensure the timer is reset.
        if [[ "$UNFOCUSED_START_TIME" -ne 0 ]]; then
            echo "[$(date +'%T')] Outside of 7 PM - 9 AM window. Deactivating countdown."
            UNFOCUSED_START_TIME=0
        fi
    fi

    # Wait for the next check
    sleep "$CHECK_INTERVAL_SECONDS"
done