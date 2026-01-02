#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Exit when using undeclared variables
set -u
# Fail on pipe errors
set -o pipefail

# ============================================================================
# Configuration Variables
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/setup_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="${HOME}/.config_backups/$(date +%Y%m%d_%H%M%S)"

# Load configuration file if it exists
CONFIG_FILE="${SCRIPT_DIR}/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Loaded configuration from $CONFIG_FILE"
else
    # Default values if no config file
    CONFIGURE_GIT="${CONFIGURE_GIT:-false}"
    GIT_EMAIL="${GIT_EMAIL:-}"
    GIT_NAME="${GIT_NAME:-$USER}"
    CHANGE_ZSH_THEME="${CHANGE_ZSH_THEME:-false}"
    ZSH_THEME="${ZSH_THEME:-robbyrussell}"
    INSTALL_GIT="${INSTALL_GIT:-true}"
    INSTALL_CHROME="${INSTALL_CHROME:-true}"
    INSTALL_BRAVE="${INSTALL_BRAVE:-true}"
    INSTALL_ZSH="${INSTALL_ZSH:-true}"
    INSTALL_PYTHON_TOOLS="${INSTALL_PYTHON_TOOLS:-true}"
    INSTALL_NODE="${INSTALL_NODE:-true}"
    INSTALL_VSCODE="${INSTALL_VSCODE:-true}"
    INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
    INSTALL_CPP_TOOLS="${INSTALL_CPP_TOOLS:-true}"
    AUTO_REBOOT="${AUTO_REBOOT:-false}"
fi

# ============================================================================
# Utility Functions
# ============================================================================

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_warning() { log "WARNING" "$@"; }
log_error() { log "ERROR" "$@"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Backup file if it exists
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        log_info "Backed up $file to $BACKUP_DIR"
    fi
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local response
    read -p "$question (y/N) " response
    [[ "$response" =~ ^[yY](es)?$ ]]
}

echo "Starting setup for Debian 13..."
log_info "Setup started by user: $USER"
log_info "Log file: $LOG_FILE"

# ============================================================================
# System Update
# ============================================================================
log_info "Updating system..."
sudo apt update && sudo apt upgrade -y
log_success "System updated successfully"

# ============================================================================
# Install Basic Dependencies
# ============================================================================
log_info "Installing basic dependencies..."
sudo apt install -y curl wget gpg apt-transport-https ca-certificates lsb-release
log_success "Basic dependencies installed"

# ============================================================================
# Install Git
# ============================================================================
if [ "$INSTALL_GIT" = "true" ]; then
    if package_installed "git"; then
        log_info "Git is already installed. Skipping installation."
    else
        log_info "Installing Git..."
        sudo apt install -y git
        log_success "Git installed successfully"
    fi

    # Configure global Git identity
    if [ "$CONFIGURE_GIT" = "true" ] && [ -n "$GIT_EMAIL" ]; then
        git config --global user.name "${GIT_NAME:-$USER}"
        git config --global user.email "$GIT_EMAIL"
        log_success "Git configured with user.name=${GIT_NAME:-$USER} and user.email=$GIT_EMAIL"
    elif ask_yes_no "Do you want to configure Git global user now?"; then
        read -p "Enter your Git email address: " git_email
        if [ -n "$git_email" ]; then
            git config --global user.name "$USER"
            git config --global user.email "$git_email"
            log_success "Git configured with user.name=$USER and user.email=$git_email"
        else
            log_warning "No email provided. Skipping Git global configuration."
        fi
    else
        log_info "Skipping Git global configuration."
    fi
else
    log_info "Git installation skipped (disabled in config)"
fi

# ============================================================================
# Install Google Chrome
# ============================================================================
if [ "$INSTALL_CHROME" = "true" ]; then
    if command_exists "google-chrome"; then
        log_info "Google Chrome is already installed. Skipping installation."
    else
        log_info "Installing Google Chrome..."
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
        sudo apt install -y /tmp/google-chrome.deb
        rm -f /tmp/google-chrome.deb
        log_success "Google Chrome installed successfully"
    fi
else
    log_info "Google Chrome installation skipped (disabled in config)"
fi

# ============================================================================
# Install Brave Browser
# ============================================================================
if [ "$INSTALL_BRAVE" = "true" ]; then
    if command_exists "brave-browser"; then
        log_info "Brave Browser is already installed. Skipping installation."
    else
        log_info "Installing Brave Browser..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
        sudo apt update
        sudo apt install -y brave-browser
        log_success "Brave Browser installed successfully"
    fi
else
    log_info "Brave Browser installation skipped (disabled in config)"
fi

# ============================================================================
# Install Zsh and Oh-My-Zsh
# ============================================================================
if [ "$INSTALL_ZSH" = "true" ]; then
    if package_installed "zsh"; then
        log_info "Zsh is already installed. Skipping installation."
    else
        log_info "Installing Zsh..."
        sudo apt install -y zsh
        log_success "Zsh installed successfully"
    fi

# Set Zsh as default shell
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [ "$current_shell" != "$(which zsh)" ]; then
    log_info "Setting Zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$USER"
    log_success "Zsh set as default shell"
else
    log_info "Zsh is already the default shell"
fi

# Install Oh-My-Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    log_info "Oh-My-Zsh is already installed. Skipping installation."
else
    log_info "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh-My-Zsh installed successfully"
fi

    # Configure Oh-My-Zsh theme
    if [ "$CHANGE_ZSH_THEME" = "true" ] && [ -n "$ZSH_THEME" ]; then
        backup_file "$HOME/.zshrc"
        if grep -q "^ZSH_THEME=" "$HOME/.zshrc"; then
            sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$ZSH_THEME\"/" "$HOME/.zshrc"
        else
            echo "ZSH_THEME=\"$ZSH_THEME\"" >> "$HOME/.zshrc"
        fi
        log_success "Oh-My-Zsh theme set to $ZSH_THEME"
    elif ask_yes_no "Do you want to change the Oh-My-Zsh theme?"; then
        echo "Available themes: agnoster, robbyrussell, bira, ys, af-magic, gnzh, etc."
        read -p "Enter the theme name you want to use: " zsh_theme
        if [ -n "$zsh_theme" ]; then
            backup_file "$HOME/.zshrc"
            if grep -q "^ZSH_THEME=" "$HOME/.zshrc"; then
                sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$zsh_theme\"/" "$HOME/.zshrc"
            else
                echo "ZSH_THEME=\"$zsh_theme\"" >> "$HOME/.zshrc"
            fi
            log_success "Oh-My-Zsh theme set to $zsh_theme"
        fi
    else
        log_info "Keeping default Oh-My-Zsh theme"
    fi
else
    log_info "Zsh installation skipped (disabled in config)"
fi

# ============================================================================
# Install Python Tools (Norminette, Flake8)
# ============================================================================
if [ "$INSTALL_PYTHON_TOOLS" = "true" ]; then
    log_info "Installing Python tools (Norminette, Flake8)..."
    sudo apt install -y python3-pip python3-venv pipx

# Ensure pipx path is configured
pipx ensurepath

# Install tools with pipx (idempotent)
if pipx list | grep -q "norminette"; then
    log_info "Norminette is already installed"
else
    pipx install norminette
    log_success "Norminette installed"
fi

    if pipx list | grep -q "flake8"; then
        log_info "Flake8 is already installed"
    else
        pipx install flake8
        log_success "Flake8 installed"
    fi
else
    log_info "Python tools installation skipped (disabled in config)"
fi

# ============================================================================
# Install Node.js and NPM
# ============================================================================
if [ "$INSTALL_NODE" = "true" ]; then
    if command_exists "node" && command_exists "npm"; then
        log_info "Node.js and NPM are already installed ($(node --version), $(npm --version))"
    else
        log_info "Installing NPM..."
        sudo apt install -y nodejs npm
        log_success "Node.js and NPM installed successfully"
    fi
else
    log_info "Node.js installation skipped (disabled in config)"
fi

# ============================================================================
# Install VS Code
# ============================================================================
if [ "$INSTALL_VSCODE" = "true" ]; then
    if command_exists "code"; then
        log_info "VS Code is already installed. Skipping installation."
    else
        log_info "Installing VS Code..."

    # Check if VS Code repo is already configured
    if grep -r "packages.microsoft.com/repos/code" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -q "microsoft.gpg"; then
        log_info "Detected existing VS Code configuration."
        # Remove conflicting configuration if it exists
        if [ -f "/etc/apt/sources.list.d/vscode.list" ]; then
            if grep -q "/etc/apt/keyrings/packages.microsoft.gpg" "/etc/apt/sources.list.d/vscode.list"; then
                log_warning "Removing conflicting /etc/apt/sources.list.d/vscode.list..."
                sudo rm -f "/etc/apt/sources.list.d/vscode.list"
            fi
        fi
    else
        # No existing config detected, proceed with standard setup
        log_info "Configuring VS Code repository..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f /tmp/packages.microsoft.gpg
    fi

        sudo apt update
        sudo apt install -y code
        log_success "VS Code installed successfully"
    fi
else
    log_info "VS Code installation skipped (disabled in config)"
fi

# ============================================================================
# Install Docker
# ============================================================================
if [ "$INSTALL_DOCKER" = "true" ]; then
    if command_exists "docker"; then
        log_info "Docker is already installed ($(docker --version))"
    else
        log_info "Installing Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        log_success "Docker installed successfully"
    fi

    # Add user to docker group
    if groups "$USER" | grep -q '\bdocker\b'; then
        log_info "$USER is already in docker group"
    else
        log_info "Adding $USER to docker group..."
        sudo usermod -aG docker "$USER"
        log_success "$USER added to docker group (requires logout to take effect)"
    fi
else
    log_info "Docker installation skipped (disabled in config)"
fi

# ============================================================================
# Install C/C++ Environment
# ============================================================================
if [ "$INSTALL_CPP_TOOLS" = "true" ]; then
    if package_installed "build-essential"; then
        log_info "C/C++ build essentials are already installed"
    else
        log_info "Installing C/C++ build essentials..."
        sudo apt install -y build-essential gdb cmake valgrind
        log_success "C/C++ build essentials installed successfully"
    fi
else
    log_info "C/C++ tools installation skipped (disabled in config)"
fi

# ============================================================================
# Completion
# ============================================================================
echo ""
echo "========================================================================"
log_success "Installation complete!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  - Log file: $LOG_FILE"
if [ -d "$BACKUP_DIR" ]; then
    echo "  - Backups: $BACKUP_DIR"
fi
echo ""
echo "IMPORTANT: It is recommended to restart your computer to apply all changes"
echo "           (groups, shell, etc.)"
echo "========================================================================"
echo ""

if [ "$AUTO_REBOOT" = "true" ]; then
    log_info "Auto-reboot enabled. Rebooting in 5 seconds..."
    echo "Rebooting in 5 seconds... Press Ctrl+C to cancel."
    sleep 5
    sudo reboot
elif ask_yes_no "Do you want to reboot now?"; then
    log_info "Rebooting system..."
    sudo reboot
else
    log_info "Setup completed without reboot. Please remember to reboot or log out/in later."
    echo "Please remember to reboot or log out/in later."
fi
