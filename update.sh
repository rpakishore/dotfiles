#!/bin/bash

# Set target file
TARGET="$HOME/.zshrc"
if [ ! -f "$TARGET" ]; then
    TARGET="$HOME/.bashrc"
fi

# Ensure the target file exists
touch "$TARGET"

# Directory containing `.zsh` files (current directory)
DIR="$(pwd)"

# Loop through `.zsh` files
for file in "$DIR"/*.zsh; do
    [ -e "$file" ] || continue  # Skip if no .zsh files exist

    # Source line to add
    SOURCE_LINE="source \"$file\""

    # Check if the line already exists in the target file
    if ! grep -Fxq "$SOURCE_LINE" "$TARGET"; then
        echo "$SOURCE_LINE" >> "$TARGET"
        echo "Added: $SOURCE_LINE"
    else
        echo "Already exists: $SOURCE_LINE"
    fi
done

# Reload shell configuration
if [[ "$TARGET" == "$HOME/.zshrc" ]]; then
    echo "Reloading Zsh configuration..."
    exec zsh  # Restart Zsh instead of sourcing it from Bash
else
    echo "Reloading Bash configuration..."
    source "$TARGET"
fi

echo "Done updating and sourcing $TARGET."
