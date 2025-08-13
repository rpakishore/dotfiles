#!/bin/bash

# --- Configuration ---
# Subdirectory (relative to PWD) containing executables to add to PATH
SCRIPTS_SUBDIR_TO_ADD_TO_PATH="scripts"

# Directory (relative to PWD) containing shell configuration snippets to source
CONFIG_SNIPPETS_DIR_RELATIVE_TO_PWD="."

# Extension of shell configuration snippets to source (e.g., .zsh, .bash, .sh)
CONFIG_SNIPPET_EXTENSION=".zsh"

# List of default packages to install with apt. Add any packages you need here.
APT_PACKAGES_TO_INSTALL=(
    	"git"
    	"xclip"		# Manipulate clipboard
    	"fzf"		# Fuzzy file lookup
	"ncdu"		# Space Lookup
)

# --- Install Default APT Packages (Idempotent) ---
# Check if apt-get is available before proceeding
if ! command -v apt-get &> /dev/null; then
    echo "INFO: 'apt-get' command not found. Skipping APT package installation."
else
    echo "INFO: Checking for required APT packages..."
    # Prompt for sudo password upfront and refresh timestamp
    echo "Package installation requires sudo. You may be asked for your password."
    sudo -v

    # Update package lists once before the loop
    echo "INFO: Updating package lists with 'sudo apt-get update'..."
    sudo apt-get update -y

    for pkg in "${APT_PACKAGES_TO_INSTALL[@]}"; do
        # Use dpkg-query to check if the package is already installed. It's efficient.
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            echo "INFO: Package '$pkg' is already installed. ✅"
        else
            echo "INSTALLING: Attempting to install package '$pkg'..."
            sudo apt-get install -y "$pkg"
            # Verify that the package was installed successfully
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                echo "SUCCESS: Package '$pkg' installed. ✨"
            else
                echo "WARNING: Failed to install or verify package '$pkg'. Please check manually. ⚠️" >&2
            fi
        fi
    done
fi

# --- Determine Target Shell Configuration File ---
# Prioritize .zshrc, then .bashrc, similar to the original script's implicit logic.
TARGET_RC_FILE="$HOME/.zshrc"
SHELL_RELOAD_COMMAND="exec zsh" # Command to suggest to the user for reloading

if [ ! -f "$TARGET_RC_FILE" ]; then
    TARGET_RC_FILE="$HOME/.bashrc"
    SHELL_RELOAD_COMMAND="source $HOME/.bashrc"
fi

# Ensure the target rc file exists, creating it if necessary.
touch "$TARGET_RC_FILE"
echo "INFO: Target shell configuration file is: $TARGET_RC_FILE"

# --- Determine Absolute Paths ---
# The script assumes it's run from a project root. Paths are relative to PWD.
CURRENT_WORKING_DIR="$(pwd)"
SCRIPTS_DIR_ABS="$CURRENT_WORKING_DIR/$SCRIPTS_SUBDIR_TO_ADD_TO_PATH"

# Resolve the absolute path for the snippets directory
# Ensures clean path, e.g., /some/path/. becomes /some/path
CONFIG_SNIPPETS_DIR_ABS=$(cd "$CURRENT_WORKING_DIR/$CONFIG_SNIPPETS_DIR_RELATIVE_TO_PWD" && pwd)

# --- Add Scripts Directory to PATH (Idempotent) ---
if [ -d "$SCRIPTS_DIR_ABS" ]; then
    # Define the exact line to add for PATH modification
    # Using \$PATH to ensure $PATH is written literally to the file
    PATH_EXPORT_LINE="export PATH=\"$SCRIPTS_DIR_ABS:\$PATH\""
    PATH_COMMENT_SIGNATURE_TEXT="Added by script: $SCRIPTS_DIR_ABS to PATH" # Used to check if our comment exists

    # Check if the exact PATH export line already exists
    if ! grep -Fxq "$PATH_EXPORT_LINE" "$TARGET_RC_FILE"; then
        echo "INFO: Adding $SCRIPTS_DIR_ABS to PATH in $TARGET_RC_FILE."
        # Add a newline for separation if the file isn't empty and doesn't end with one
        [ -s "$TARGET_RC_FILE" ] && [ "$(tail -c1 "$TARGET_RC_FILE")" != "" ] && echo "" >> "$TARGET_RC_FILE"
        
        # Add a comment if a similar one isn't already there
        if ! grep -Fq "$PATH_COMMENT_SIGNATURE_TEXT" "$TARGET_RC_FILE"; then
            echo "" >> "$TARGET_RC_FILE" # Blank line before comment
            echo "# $PATH_COMMENT_SIGNATURE_TEXT" >> "$TARGET_RC_FILE"
        fi
        echo "$PATH_EXPORT_LINE" >> "$TARGET_RC_FILE"
        echo "SUCCESS: Added to PATH: $SCRIPTS_DIR_ABS"
    else
        echo "INFO: PATH already includes '$SCRIPTS_DIR_ABS' with the specific line: $PATH_EXPORT_LINE"
    fi
else
    echo "WARNING: Scripts directory '$SCRIPTS_DIR_ABS' not found. Skipping PATH addition."
fi

# --- Source Shell Configuration Snippets (Idempotent) ---
SNIPPETS_COMMENT_SIGNATURE_TEXT="Source custom configuration snippets (managed by script)"
ADDED_SNIPPETS_COMMENT_FLAG=false # To ensure main comment is added only once if needed

echo "INFO: Looking for '$CONFIG_SNIPPET_EXTENSION' files in '$CONFIG_SNIPPETS_DIR_ABS' to source..."
# Using an array to handle cases where no files match the glob
SHOPT_NULLGLOB_STATE=$(shopt -p nullglob) # Save current nullglob state
shopt -s nullglob # Enable nullglob to make glob expand to nothing if no match
FILES_TO_SOURCE=("$CONFIG_SNIPPETS_DIR_ABS"/*"$CONFIG_SNIPPET_EXTENSION")
eval "$SHOPT_NULLGLOB_STATE" # Restore nullglob state

if [ ${#FILES_TO_SOURCE[@]} -gt 0 ]; then
    for snippet_file_path_abs in "${FILES_TO_SOURCE[@]}"; do
        # Ensure it's a file, not a directory or broken symlink etc.
        if [ -f "$snippet_file_path_abs" ]; then
            SOURCE_LINE="source \"$snippet_file_path_abs\""

            if ! grep -Fxq "$SOURCE_LINE" "$TARGET_RC_FILE"; then
                echo "INFO: Adding source line for '$snippet_file_path_abs'."
                # Add the main comment for this section if it's the first time and not already present
                if ! $ADDED_SNIPPETS_COMMENT_FLAG && ! grep -Fq "$SNIPPETS_COMMENT_SIGNATURE_TEXT" "$TARGET_RC_FILE"; then
                    # Add a newline for separation if the file isn't empty and doesn't end with one
                    [ -s "$TARGET_RC_FILE" ] && [ "$(tail -c1 "$TARGET_RC_FILE")" != "" ] && echo "" >> "$TARGET_RC_FILE"
                    echo "" >> "$TARGET_RC_FILE" # Blank line before comment
                    echo "# $SNIPPETS_COMMENT_SIGNATURE_TEXT" >> "$TARGET_RC_FILE"
                    ADDED_SNIPPETS_COMMENT_FLAG=true
                elif grep -Fq "$SNIPPETS_COMMENT_SIGNATURE_TEXT" "$TARGET_RC_FILE"; then
                     # If comment already exists, mark flag as true so we don't try to add it again for subsequent files
                    ADDED_SNIPPETS_COMMENT_FLAG=true
                fi
                
                echo "$SOURCE_LINE" >> "$TARGET_RC_FILE"
                echo "SUCCESS: Added source line for: $snippet_file_path_abs"
            else
                echo "INFO: Source line already exists for: $snippet_file_path_abs"
            fi
        else
            echo "WARNING: Skipping '$snippet_file_path_abs', as it is not a regular file."
        fi
    done
else
    echo "INFO: No '$CONFIG_SNIPPET_EXTENSION' files found in '$CONFIG_SNIPPETS_DIR_ABS' to source."
fi

# --- Final Instructions ---
echo ""
echo "INFO: Setup script finished."
echo "To apply all changes to your current shell, please run the following command:"
echo "  $SHELL_RELOAD_COMMAND"
echo "Alternatively, you can open a new terminal window/tab."
