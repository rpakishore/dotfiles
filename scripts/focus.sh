#!/bin/bash

# ==============================================================================
# Script Name: focus.sh
# Description: This script modifies the GNOME Shell panel clock format to
#              display a custom "Focus" message. It can also set a timer,
#              after which the focus message is automatically cleared.
#
# Author:      Based on concept from paepper.com
#              (https://www.paepper.com/blog/posts/how-i-hacked-my-clock-to-control-my-focus.md/)
# Version:     1.2 (Added Session Timer, getopts, improved robustness)
# Date:        May 14, 2025
#
# Requirements:
#   1. GNOME Shell environment.
#   2. `dconf`: Command-line utility for GNOME settings.
#   3. `sleep`: Command that supports duration suffixes (e.g., '25m', '1h').
#      (Standard on most Linux distributions and macOS).
#   4. A GNOME Shell extension for custom panel date/time format via dconf.
#      Default key: /org/gnome/shell/extensions/panel-date-format/format
#      (e.g., "Panel Date Format" extension). Update DCONF_KEY if needed.
#   5. Optional: `notify-send` for desktop notifications when timer ends.
#
# Usage:
#   ./focus.sh [OPTIONS] [FOCUS_MESSAGE] [TIMER_DURATION]
#
# Options:
#   -m "MESSAGE"   : Set the focus message.
#   -t DURATION    : Set a timer for the focus (e.g., "25m", "1h", "90s").
#                    Requires -m or a positional FOCUS_MESSAGE.
#                    The focus message will be cleared after DURATION.
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
#   Clear focus:
#     ./focus.sh -c
#     Run script and enter blank focus when prompted.
#
#   Interactive mode (if no arguments):
#     ./focus.sh
#     (Prompts for focus; timer not available in interactive mode via prompt)
#
# How it works:
#   Uses `dconf` to change the GNOME panel clock format. For timers, it
#   starts a background process that sleeps for the specified duration and
#   then resets the clock format. A PID file is used to manage the timer.
# ==============================================================================

# --- Configuration ---
DCONF_KEY="/org/gnome/shell/extensions/panel-date-format/format"
DEFAULT_FORMAT="'%b %d  %H:%M'" # Example: 'May 14  09:30'
PID_FILE="/tmp/gnome_focus_timer.pid" # File to store the PID of the timer process

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
    echo "  $0 -c"
    echo "  $0 (interactive mode)"
}

# Function to kill any existing timer process
kill_existing_timer() {
    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            kill "$old_pid" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
}

# Function to set the GNOME focus message, optionally with a timer
# Arguments:
#   $1: Focus text string
#   $2: Timer duration string (e.g., "25m", "1h", or empty for no timer)
set_gnome_focus() {
    local focus_text="$1"
    local timer_duration="$2"

    # Trim whitespace from focus_text
    focus_text=$(echo "$focus_text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$focus_text" ]; then
        echo "Error: Focus text cannot be empty when setting focus. Use -c to clear." >&2
        # Or, if desired, could call clear_gnome_focus here.
        # For now, exiting as it's likely a usage error if this function is called with empty.
        exit 1
    fi

    kill_existing_timer # Stop any previous timer

    local new_format="'%b %d  %H:%M  Focus: $focus_text'"
    dconf write "$DCONF_KEY" "$new_format"
    echo "Focus set to: $focus_text"

    if [ -n "$timer_duration" ]; then
        # Basic validation for timer_duration. `sleep` will do more thorough checking.
        # This regex is very basic and mainly checks for common patterns.
        # `sleep` often supports more complex inputs like "1.5h".
        if ! echo "$timer_duration" | grep -Eq '^[0-9]+(\.[0-9]+)?[smhd]?$|^[0-9]+[smhd]$'; then
            echo "Warning: Timer duration '$timer_duration' format might be unusual. `sleep` will attempt to parse it."
        fi

        # Start the timer process in the background
        (
            # This subshell runs in the background.
            # It inherits DCONF_KEY, DEFAULT_FORMAT, PID_FILE, and focus_text.
            # BASHPID refers to the PID of this subshell.

            # Sleep for the specified duration.
            # Errors from sleep (e.g., invalid format) are suppressed from stdout/stderr here.
            sleep "$timer_duration" 2>/dev/null

            # After waking up, check if this timer is still the "active" one.
            # This prevents a stale timer (whose PID was overwritten in PID_FILE by a newer timer,
            # or removed by a clear command) from incorrectly clearing the focus.
            if [ -f "$PID_FILE" ] && [ "$(cat "$PID_FILE")" -eq "$BASHPID" ]; then
                dconf write "$DCONF_KEY" "$DEFAULT_FORMAT"
                echo "[Timer] Focus session for '$focus_text' ended. Clock format reset."
                # Optional: Send a desktop notification. Requires `notify-send`.
                # if command -v notify-send >/dev/null; then
                #    notify-send "Focus Timer Ended" "Session for '$focus_text' is complete."
                # fi
                rm -f "$PID_FILE" # Clean up its own PID file as it completed.
            # else
                # This timer was superseded or cleared externally. Do nothing.
                # echo "[Timer] Stale timer for '$focus_text' exiting without action." # For debugging
            fi
        ) &
        local timer_pid=$! # Get the PID of the backgrounded subshell
        echo "$timer_pid" > "$PID_FILE" # Store it
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

# Parse command-line options using getopts
# The leading colon in ":m:t:ch" enables silent error handling for invalid options / missing args,
# allowing custom messages.
while getopts ":m:t:ch" opt; do
  case $opt in
    m) opt_focus_message="$OPTARG" ;;
    t) opt_timer_duration="$OPTARG" ;;
    c) opt_clear_focus=true ;;
    h) opt_show_help=true ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; display_help; exit 1 ;;
    :) echo "Error: Option -$OPTARG requires an argument." >&2; display_help; exit 1 ;;
  esac
done
# Shift processed options away, so $1, $2, etc. refer to remaining non-option arguments
shift $((OPTIND-1))

# --- Determine and Execute Action ---

# Handle -h (help) first
if $opt_show_help; then
    display_help
    exit 0
fi

# Handle -c (clear focus)
if $opt_clear_focus; then
    # -c takes precedence. If -c is present, other focus-setting options are ignored.
    clear_gnome_focus
    exit 0
fi

# Handle setting focus if -m was used
if [ -n "$opt_focus_message" ]; then
    # Trim whitespace from message provided by -m
    opt_focus_message_trimmed=$(echo "$opt_focus_message" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$opt_focus_message_trimmed" ]; then
        # Treat -m "" (empty message) as a request to clear focus for consistency
        echo "Focus message provided with -m is empty. Clearing focus."
        clear_gnome_focus
    else
        set_gnome_focus "$opt_focus_message_trimmed" "$opt_timer_duration"
    fi
    exit 0
fi

# If -t was used without -m, it's an error (unless positional message is provided later)
if [ -n "$opt_timer_duration" ] && [ -z "$opt_focus_message" ]; then
    # Check if there's a positional argument that could be the message
    if [ $# -eq 0 ]; then # No positional arguments left
        echo "Error: Timer (-t) specified without a focus message (-m or positional)." >&2
        display_help
        exit 1
    fi
    # If there are positional args, they will be handled next.
fi

# Handle positional arguments if no primary option (-m, -c, -h) has led to an exit yet
if [ $# -gt 0 ]; then
    # First positional argument is the focus message
    pos_focus_message="$1"
    pos_timer_duration="" # Default to no timer from positional args

    if [ $# -gt 1 ]; then
        # Second positional argument (if present) is the timer duration
        pos_timer_duration="$2"
    fi
    
    # If -t was specified earlier, but -m was not, and we now have a positional message.
    # Prioritize -t if it was explicitly given.
    if [ -n "$opt_timer_duration" ] && [ -z "$pos_timer_duration" ]; then
        pos_timer_duration="$opt_timer_duration"
    fi

    # Trim whitespace from positional focus message
    pos_focus_message_trimmed=$(echo "$pos_focus_message" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$pos_focus_message_trimmed" ]; then
        # Empty positional focus message means clear
        clear_gnome_focus
    else
        set_gnome_focus "$pos_focus_message_trimmed" "$pos_timer_duration"
    fi
    exit 0
fi

# Interactive mode: if no options or arguments resulted in an action
# This condition means: not -h, not -c, no -m, no positional args,
# AND if -t was given, it didn't have a message from -m or positional.
if [ -z "$opt_focus_message" ] && ! $opt_clear_focus && ! $opt_show_help && [ $# -eq 0 ]; then
    if [ -n "$opt_timer_duration" ]; then # Case: only -t was given, no message
        echo "Error: Timer (-t) specified without a focus message (-m or positional)." >&2
        display_help
        exit 1
    fi

    echo "What's your current focus? (Leave blank to clear focus)"
    read -r interactive_focus_text # -r to prevent backslash interpretation

    # Trim whitespace
    interactive_focus_text_trimmed=$(echo "$interactive_focus_text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$interactive_focus_text_trimmed" ]; then
        clear_gnome_focus
    else
        # No timer option via interactive prompt in this version for simplicity
        set_gnome_focus "$interactive_focus_text_trimmed" ""
    fi
    exit 0
fi

# If script reaches here, it means some combination of inputs was not handled
# or was ambiguous. Display help as a fallback.
# This typically shouldn't be reached if logic above is complete.
# echo "Debug: Unhandled argument combination." # For debugging
display_help
exit 1
