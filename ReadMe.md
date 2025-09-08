# dotfiles

A comprehensive collection of Linux configuration files and scripts to enhance your development environment with productivity tools, shell aliases, SSH configurations, and GNOME desktop enhancements.

## Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Configuration Components](#configuration-components)
- [Scripts](#scripts)
- [Usage Examples](#usage-examples)
- [Customization](#customization)

## Features

### 🚀 Productivity Enhancements

- **Extensive Shell Aliases**: 100+ aliases for common commands, navigation, and external tools
- **Smart Package Management**: Automatic installation of essential development tools
- **Clipboard Management**: Enhanced clipboard utilities with xclip integration
- **Docker Utilities**: Comprehensive Docker aliases and cleanup functions

### 🔧 Development Tools Integration

- **Version Control**: Git workflow optimizations
- **File Management**: Enhanced file operations with safety features
- **Network Tools**: IP address utilities and SSH shortcuts
- **Media Processing**: FFmpeg and yt-dlp aliases for media handling

### 🖥️ GNOME Desktop Enhancements

- **Focus Timer**: GNOME panel integration for productivity tracking
- **Screen Lock Automation**: Intelligent screen locking based on focus state
- **Custom Panel Display**: Dynamic panel clock with focus messages

### 🔐 SSH Configuration

- **Pre-configured SSH Aliases**: Quick access to frequently used servers
- **Organized Connection Management**: Easy server switching and management

## System Requirements

### Core Requirements

- **Operating System**: Ubuntu/Debian-based Linux distribution
- **Shell**: Zsh (with bash fallback)
- **Desktop Environment**: GNOME Shell (for focus features)

### Recommended Packages

- `git` - Version control
- `xclip` - Clipboard management
- `fzf` - Fuzzy file finder
- `ncdu` - Disk usage analyzer
- `dconf` - GNOME configuration (for focus features)

### Optional Dependencies

- `aria2c` - Enhanced download capabilities
- `bat` - Syntax-highlighted file viewer
- `docker` - Container management
- `ffmpeg` - Media processing
- `yt-dlp` - Video downloading
- `speedtest-cli` - Network speed testing

## Installation

### Fresh Installation

```bash
# Clone the repository
git clone https://github.com/rpakishore/dotfiles.git
cd dotfiles

# Make the setup script executable and run it
chmod +x update.sh
./update.sh
```

### Update Existing Installation

```bash
# Pull latest changes and update
git pull
./update.sh
```

### Post-Installation

After running the setup script, apply the changes to your current shell:

```bash
# For Zsh users
exec zsh

# For Bash users
source ~/.bashrc
```

## Configuration Components

### Shell Configuration Files

#### `aliases.zsh`

Comprehensive collection of shell aliases including:

- **File Operations**: Enhanced `cp`, `mv`, `ls` with safety features
- **Navigation**: Quick directory jumping (`..`, `...`, `home`, `bd`)
- **Docker**: Container management (`docker-ps`, `docker-clean`, `docker-update`)
- **External Tools**: Integration with `bat`, `fzf`, `ncdu`, `xclip`, `yt-dlp`, etc.
- **Network**: IP utilities and SSH shortcuts
- **Media**: FFmpeg and download optimizations

#### `ssh_ip.zsh`

Pre-configured SSH aliases for quick server access:

- `shpihole` - Pi-hole server
- `shprx-01-gpt` - GPT server
- `shprx-01-struct` - Structure server
- `shrasp-01-mm` - Raspberry Pi multimedia
- `shubuntu-server` - Ubuntu server

## Scripts

### Focus Management System

#### `focus.sh`

A sophisticated GNOME panel focus timer that displays custom messages on your desktop clock.

**Features:**

- Set custom focus messages on GNOME panel clock
- Built-in timer functionality with automatic clearing
- Background process management with PID tracking
- Interactive and command-line modes

**Usage:**

```bash
# Set a simple focus message
./scripts/focus.sh "Deep Work Session"

# Set focus with timer (45 minutes)
./scripts/focus.sh "Coding Sprint" 45m

# Clear current focus
./scripts/focus.sh -c

# Interactive mode
./scripts/focus.sh
```

#### `focus_monitor.sh`

Background service that monitors focus state and automatically locks the screen when unfocused for too long during specific hours.

**Features:**

- Monitors GNOME panel for focus messages
- Automatic screen locking after 10 minutes of inactivity
- Time-window based activation (7 PM - 9 AM)
- Background daemon with logging

**Usage:**

```bash
# Start the focus monitor (runs continuously)
./scripts/focus_monitor.sh
```

## Usage Examples

### Daily Development Workflow

```bash
# Update system and packages
update

# Navigate efficiently
..          # Go up one directory
lll         # List files with details
la          # Show hidden files

# Docker management
docker-ps   # View all containers with ports
docker-clean # Clean up unused containers and volumes

# Network utilities
ipv4        # Show IPv4 addresses
speedtest-cli # Test internet speed

# Media downloads
yt-dlp "https://youtube.com/watch?v=..."  # Download with optimized settings
```

### Focus Session Management

```bash
# Start a focused work session
./scripts/focus.sh "Important Project Work" 90m

# The GNOME panel will show: "May 14  14:30  Focus: Important Project Work"
# After 90 minutes, the focus will automatically clear

# Start background monitor for productivity tracking
./scripts/focus_monitor.sh &
```

### SSH Server Access

```bash
# Quick server connections
shpihole      # Connect to Pi-hole
shubuntu-server  # Connect to Ubuntu server
```

## Customization

### Adding New Aliases

Edit `aliases.zsh` to add your own aliases:

```bash
# Example: Add your own alias
alias myproject='cd /path/to/my/project'
```

### Modifying Package List

Edit the `APT_PACKAGES_TO_INSTALL` array in `update.sh` to customize installed packages.

### Focus Timer Configuration

Modify settings in `scripts/focus.sh`:

- `DCONF_KEY`: GNOME panel date format key
- `DEFAULT_FORMAT`: Default clock format
- Timer behavior and notifications

### Monitor Settings

Adjust `scripts/focus_monitor.sh` variables:

- `LOCK_THRESHOLD_SECONDS`: Time before auto-lock (default: 600)
- `CHECK_INTERVAL_SECONDS`: Monitoring frequency (default: 60)

## Contributing

Feel free to submit issues, feature requests, or pull requests to enhance this dotfiles collection.

## License

This project is open source and available under the MIT License.
