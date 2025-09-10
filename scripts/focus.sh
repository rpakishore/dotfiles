#!/bin/bash

# ==============================================================================
# Script Name: focus.sh
# Description: This script modifies the GNOME Shell panel clock format to
#              display a custom "Focus" message. It can also set a timer,
#              after which the focus message is automatically cleared.
#
# Author:      Based on concept from paepper.com
#              (https://www.paepper.com/blog/posts/how-i-hacked-my-clock-to-control-my-focus.md/)
# Version:     2.0 (Refactored logic, added status, improved performance)
# Date:        September 10, 2025
#
# Requirements:
#   1. GNOME Shell environment.
#   2. `dconf`: Command-line utility for GNOME settings.
#   3. `sleep`: Command that supports duration suffixes (e.g., '25m', '1h').
#   4. A GNOME Shell extension for custom panel date/time format via dconf.
#      Default key: /org/gnome/shell/extensions/panel-date-format/format
#      (e.g., "Panel Date Format" extension). Update DCONF_KEY if needed.
#   5. `notify-send` for desktop notifications when timer ends.
#
# Usage:
#   ./focus.sh [OPTIONS] [FOCUS_MESSAGE] [TIMER_DURATION]
#
# Options:
#   -m "MESSAGE"   : Set the focus message.
#   -t DURATION    : Set a timer for the focus (e.g., "25m", "1h", "90s").
#                    Requires -m or a positional FOCUS_MESSAGE.
#                    The focus message will be cleared after DURATION.
#   -s             : Check the status of the current focus session.
#   -c             : Clear the current focus message and any active timer.
#   -h             : Display this help message.
#
# Positional Arguments (if no options like -m, -c, -h are used):
#   FOCUS_MESSAGE  : The text to display as your focus.
#   TIMER_DURATION : (Optional) Duration for the focus (e.g., "25m", "1h").
#
# Examples:
#   Set focus:
#     ./focus.sh -m "Deep Work Session"
#     ./focus.sh "Client Project X"
#
#   Set focus with a timer:
#     ./focus.sh -m "Coding Sprint" -t 45m
#     ./focus.sh "Read Chapter 5" 30m
#
#   Check status:
#     ./focus.sh -s
#
#   Clear focus:
#     ./focus.sh -c
#
#   Interactive mode (if no arguments):
#     ./focus.sh
#
# How it works:
#   Uses `dconf` to change the GNOME panel clock format. For timers, it
#   starts a background process that sleeps for the specified duration and
#   then resets the clock format. A PID file is used to manage the timer
#   state, including the PID, end time, and focus message.
# ==============================================================================

# --- Configuration ---
DCONF_KEY="/org/gnome/shell/extensions/panel-date-format/format"
DEFAULT_FORMAT="'%b %d  %H:%M'" # Example: 'Sep 10  09:30'
# File to store timer info: PID;END_TIMESTAMP;FOCUS_MESSAGE
PID_FILE="/tmp/gnome_focus_timer.pid"

# --- Helper Functions ---

# Function to display help message
display_help() {
    echo "Usage: $0 [OPTIONS] [FOCUS_MESSAGE] [TIMER_DURATION]"
    echo ""
    echo "Modifies the GNOME Shell panel clock to display a focus message, optionally with a timer."
    echo ""
    echo "Options:"
    echo "  -m \"MESSAGE\"   Set the focus message."
    echo "  -t DURATION    Set a timer (e.g., \"25m\", \"1h\"). Requires a focus message."
    echo "  -s             Check status of the current focus session."
    echo "  -c             Clear current focus message and timer."
    echo "  -h             Display this help message."
    echo ""
    echo "Positional Arguments (if no options like -m, -c, -h are used):"
    echo "  FOCUS_MESSAGE  The text for your focus."
    echo "  TIMER_DURATION (Optional) Duration for the focus (e.g., \"25m\", \"1h\")."
    echo ""
    echo "Examples:"
    echo "  $0 -m \"Deep Work\" -t 1h"
    echo "  $0 \"Client Project\" 45m"
    echo "  $0 -s"
    echo "  $0 -c"
    echo "  $0 (interactive mode)"
}

# Function to kill any existing timer process
kill_existing_timer() {
    if [[ -f "$PID_FILE" ]]; then
        # Read only the PID, which is the first field before a semicolon
        local old_pid
        old_pid=$(cut -d';' -f1 "$PID_FILE")
        if [[ -n "$old_pid" ]] && ps -p "$old_pid" > /dev/null 2>&1; then
            kill "$old_pid" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
}

# Function to display status of the current focus session
display_status() {
    if [[ -f "$PID_FILE" ]]; then
        # Timer-based focus session is active or stale.
        IFS=';' read -r pid end_time focus_text < "$PID_FILE"

        if [[ -z "$pid" ]] || ! ps -p "$pid" > /dev/null 2>&1; then
            echo "Stale focus session found. Clearing..."
            rm -f "$PID_FILE"
            # Check dconf as a fallback to see if a non-timed focus is set
            local current_format
            current_format=$(dconf read "$DCONF_KEY")
            if [[ "$current_format" != "$DEFAULT_FORMAT" && "$current_format" =~ Focus:\ (.*)\'$ ]]; then
                local focus_text="${BASH_REMATCH[1]}"
                echo "Found non-timed focus: '$focus_text'"
            else
                echo "No active focus session."
            fi
            exit 0 # Exit cleanly after clearing stale session
        fi

        local now
        now=$(date +%s)
        local remaining_seconds=$((end_time - now))

        if [[ "$remaining_seconds" -le 0 ]]; then
            echo "Focus session for '$focus_text' has just ended or is stale."
        else
            local mins=$((remaining_seconds / 60))
            local secs=$((remaining_seconds % 60))
            echo "Active focus: '$focus_text'"
            printf "Time remaining: %d minutes and %d seconds\n" "$mins" "$secs"
        fi
    else
        # No timer file, check dconf for a manually set focus message.
        local current_format
        current_format=$(dconf read "$DCONF_KEY")

        if [[ "$current_format" == "$DEFAULT_FORMAT" ]]; then
            echo "No active focus session."
        elif [[ "$current_format" =~ Focus:\ (.*)\'$ ]]; then
            local focus_text="${BASH_REMATCH[1]}"
            echo "Active focus (no timer): '$focus_text'"
        else
            echo "A custom clock format is set, but it may not be a focus session."
            echo "Current format: $current_format"
        fi
    fi
}

# Function to set the GNOME focus message, optionally with a timer
set_gnome_focus() {
    local focus_text="$1"
    local timer_duration="$2"

    # The calling logic should already trim, but as a safeguard:
    read -r focus_text <<< "$focus_text"

    if [[ -z "$focus_text" ]]; then
        echo "Error: Focus text cannot be empty when setting focus. Use -c to clear." >&2
        exit 1
    fi

    kill_existing_timer # Stop any previous timer

    local new_format="'%b %d  %H:%M  Focus: $focus_text'"
    dconf write "$DCONF_KEY" "$new_format"
    echo "Focus set to: $focus_text"

    if [[ -n "$timer_duration" ]]; then
        if ! echo "$timer_duration" | grep -Eq '^[0-9]+(\.[0-9]+)?[smhd]?$|^[0-9]+[smhd]$'; then
            echo "Warning: Timer duration '$timer_duration' format might be unusual. \`sleep\` will attempt to parse it."
        fi

        # Start the timer process in the background
        (
            # This subshell runs in the background.
            sleep "$timer_duration" 2>/dev/null

            # After waking up, check if this timer is still the "active" one.
            local current_pid_from_file
            current_pid_from_file=$(cut -d';' -f1 "$PID_FILE")
            if [[ -f "$PID_FILE" && "$current_pid_from_file" == "$BASHPID" ]]; then
                dconf write "$DCONF_KEY" "$DEFAULT_FORMAT"
                echo "[Timer] Focus session for '$focus_text' ended. Clock format reset."
                # Send a desktop notification.
                if command -v notify-send >/dev/null; then
                   notify-send "Focus Timer Ended" "Session for '$focus_text' is complete."
                fi
                rm -f "$PID_FILE" # Clean up its own PID file as it completed.
            fi
        ) & # The '&' here is crucial for backgrounding
        local timer_pid=$!
        local end_time
        end_time=$(date -d "now + $(echo "$timer_duration" | sed -e 's/m/ minutes/' -e 's/h/ hours/' -e 's/s/ seconds/')" +%s)
        # Store PID, end time, and the original focus text
        echo "$timer_pid;$end_time;$focus_text" > "$PID_FILE"
        echo "Timer active for $timer_duration. Focus will be cleared automatically."
        echo "(Timer PID: $timer_pid)"
    fi
}

# Function to clear the GNOME focus message and any active timer
clear_gnome_focus() {
    kill_existing_timer # Stop any active timer
    dconf write "$DCONF_KEY" "$DEFAULT_FORMAT"
    echo "Focus cleared. Clock format reset to default."
}

# --- Main Script Logic ---

# Initialize variables for parsed options
opt_focus_message=""
opt_timer_duration=""
opt_clear_focus=false
opt_show_help=false
opt_show_status=false

# Parse command-line options using getopts
while getopts ":m:t:sch" opt; do
  case $opt in
    m) opt_focus_message="$OPTARG" ;; 
    t) opt_timer_duration="$OPTARG" ;; 
    s) opt_show_status=true ;; 
    c) opt_clear_focus=true ;; 
    h) opt_show_help=true ;; 
    \?) echo "Error: Invalid option -$OPTARG" >&2; display_help; exit 1 ;; 
    :) echo "Error: Option -$OPTARG requires an argument." >&2; display_help; exit 1 ;; 
  esac
done
# Shift processed options away, so $1, $2, etc. refer to remaining non-option arguments
shift $((OPTIND-1))

# --- Determine and Execute Action ---

# 1. Handle exclusive options that cause an immediate exit
if [[ "$opt_show_help" == true ]]; then
    display_help
    exit 0
fi

if [[ "$opt_clear_focus" == true ]]; then
    clear_gnome_focus
    exit 0
fi

if [[ "$opt_show_status" == true ]]; then
    display_status
    exit 0
fi

# 2. Determine the final message and timer from all available sources
#    Flags (-m, -t) take precedence over positional arguments ($1, $2).
final_message="${opt_focus_message:-$1}"
final_timer="${opt_timer_duration:-$2}"

# 3. Act based on the determined message and timer
if [[ -n "$final_message" ]]; then
    # A message was provided via -m or positional arg.
    # Trim whitespace to check if it's effectively empty.
    read -r final_message_trimmed <<< "$final_message"
    if [[ -z "$final_message_trimmed" ]]; then
        # Treat empty message as a request to clear.
        echo "Focus message is empty. Clearing focus."
        clear_gnome_focus
    else
        set_gnome_focus "$final_message_trimmed" "$final_timer"
    fi
elif [[ -n "$final_timer" ]]; then
    # A timer was provided (-t or positional) but there was no message.
    echo "Error: Timer specified without a focus message (-m or positional)." >&2
    display_help
    exit 1
else
    # No arguments were provided at all, so enter interactive mode.
    echo "What's your current focus? (Leave blank to clear focus)"
    read -r interactive_focus_text

    # Trim whitespace
    read -r interactive_focus_text_trimmed <<< "$interactive_focus_text"

    if [[ -z "$interactive_focus_text_trimmed" ]]; then
        clear_gnome_focus
    else
        # No timer option via interactive prompt for simplicity
        set_gnome_focus "$interactive_focus_text_trimmed" ""
    fi
fi

exit 0