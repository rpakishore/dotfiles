#!/bin/bash

# ==============================================================================
# Script Name: focus_monitor.sh
# Description: A background service that monitors the GNOME panel clock format.
#              If a "Focus:" message is not present for a set duration
#              between specified hours, it locks the screen.
#
# Author:      Gemini, for the user
# Version:     2.0
# Date:        September 10, 2025
#
# Changes in 2.0:
#   - Switched from echo to syslog for logging via `logger`.
#   - Added a lock file to ensure only one instance of the script runs.
#   - Added dependency checks for `dconf` and `xdg-screensaver`.
#   - Encapsulated logic into functions for better readability.
#   - Made configuration variables readonly.
# ==============================================================================

# --- Configuration ---
# This MUST match the key in your focus.sh script
readonly DCONF_KEY="/org/gnome/shell/extensions/panel-date-format/format"

# The script will only be active between these hours (24-hour format).
readonly START_HOUR=19
readonly END_HOUR=8

# Lock the screen after being unfocused for this many seconds (10 minutes = 600 seconds)
readonly LOCK_THRESHOLD_SECONDS=600

# How often to check the status, in seconds
readonly CHECK_INTERVAL_SECONDS=60

# --- Script Setup ---
readonly SCRIPT_NAME=$(basename "$0")
readonly LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
readonly LOG_TAG="focus_monitor"

# --- Functions ---

# Log messages to syslog
log() {
    logger -t "$LOG_TAG" "$1"
}

# Check for required commands
check_dependencies() {
    for cmd in dconf xdg-screensaver; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR: Required command '$cmd' is not installed. Exiting."
            exit 1
        fi
    done
}

# Cleanup function to remove the lock file on exit
cleanup() {
    rm -f "$LOCK_FILE"
    log "Stopped."
}

# Check if the current time is within the active monitoring window.
# Handles overnight windows (e.g., 19:00 to 08:00).
is_in_active_window() {
    local current_hour
    current_hour=$(date +%H)
    if [[ "$current_hour" -ge "$START_HOUR" || "$current_hour" -lt "$END_HOUR" ]]; then
        return 0 # true
    else
        return 1 # false
    fi
}

# --- Main Logic ---
main() {
    check_dependencies

    # Ensure only one instance is running using a PID lock file.
    if [ -f "$LOCK_FILE" ]; then
        # Check if the process ID from the lock file is still running.
        if ps -p "$(cat "$LOCK_FILE")" > /dev/null; then
            log "Another instance is already running. Exiting."
            exit 1
        else
            # The process is not running, so the lock file is stale.
            log "Found stale lock file. Removing it."
            rm -f "$LOCK_FILE"
        fi
    fi
    # Create a new lock file with the current process ID.
    echo $$ > "$LOCK_FILE"

    # Register the cleanup function to run on script exit.
    trap cleanup EXIT INT TERM

    # State variable: Stores the Unix timestamp of when the "unfocused" state began. 0 means focused.
    local UNFOCUSED_START_TIME=0

    log "Starting. Will lock screen after $LOCK_THRESHOLD_SECONDS seconds of no focus between ${START_HOUR}:00 and ${END_HOUR}:00."

    while true; do
        if is_in_active_window; then
            local current_format
            current_format=$(dconf read "$DCONF_KEY")

            if [[ "$current_format" == *"Focus:"* ]]; then
                if [[ "$UNFOCUSED_START_TIME" -ne 0 ]]; then
                    log "Focus has been set. Countdown cancelled."
                    UNFOCUSED_START_TIME=0
                fi
            else
                if [[ "$UNFOCUSED_START_TIME" -eq 0 ]]; then
                    UNFOCUSED_START_TIME=$(date +%s)
                    log "No focus set. Starting ${LOCK_THRESHOLD_SECONDS}s lock countdown."
                else
                    local current_time elapsed_seconds
                    current_time=$(date +%s)
                    elapsed_seconds=$((current_time - UNFOCUSED_START_TIME))

                    if [[ "$elapsed_seconds" -gt "$LOCK_THRESHOLD_SECONDS" ]]; then
                        log "Unfocused for over $LOCK_THRESHOLD_SECONDS seconds. Locking screen!"
                        xdg-screensaver lock
                        UNFOCUSED_START_TIME=0 # Reset timer
                    fi
                fi
            fi
        else
            if [[ "$UNFOCUSED_START_TIME" -ne 0 ]]; then
                log "Outside of ${START_HOUR}:00 - ${END_HOUR}:00 window. Deactivating countdown."
                UNFOCUSED_START_TIME=0
            fi
        fi

        sleep "$CHECK_INTERVAL_SECONDS"
    done
}

# --- Run Script ---
main
