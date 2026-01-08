#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Exit when using undeclared variables
set -u
# Fail on pipe errors
set -o pipefail

# ============================================================================
# SSH Keys Setup Script
# ============================================================================
# This script copies SSH keys from a VirtualBox shared folder to the home
# directory and sets appropriate permissions.
# ============================================================================

# Configuration
SSH_SOURCE_DIR="/media/sf_.ssh"
SSH_TARGET_DIR="$HOME/.ssh"
LOG_FILE="${SSH_TARGET_DIR}/ssh_setup_$(date +%Y%m%d_%H%M%S).log"

# Logging functions
log_info() {
    local message="$1"
    echo "[INFO] $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo "[SUCCESS] $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo "[ERROR] $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo "[WARNING] $message" | tee -a "$LOG_FILE"
}

# Check if source directory exists
if [ ! -d "$SSH_SOURCE_DIR" ]; then
    log_error "Source directory $SSH_SOURCE_DIR does not exist!"
    echo "Please ensure:"
    echo "  1. VirtualBox Guest Additions are installed"
    echo "  2. The shared folder is properly configured"
    echo "  3. The shared folder name is '.ssh'"
    exit 1
fi

# Ask for confirmation
read -p "Do you want to copy SSH keys from $SSH_SOURCE_DIR to $SSH_TARGET_DIR? (y/N) " response
if [[ ! "$response" =~ ^[yY](es)?$ ]]; then
    log_info "SSH keys copy cancelled by user."
    exit 0
fi

# Create target directory if it doesn't exist
if [ ! -d "$SSH_TARGET_DIR" ]; then
    log_info "Creating directory $SSH_TARGET_DIR..."
    sudo mkdir -p "$SSH_TARGET_DIR"
fi

# Backup existing SSH keys
if [ -f "$SSH_TARGET_DIR/id_rsa" ] || [ -f "$SSH_TARGET_DIR/id_rsa.pub" ]; then
    BACKUP_DIR="${HOME}/.ssh_backup_$(date +%Y%m%d_%H%M%S)"
    log_warning "Existing SSH keys found. Creating backup in $BACKUP_DIR..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r "$SSH_TARGET_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    log_success "Backup created successfully"
fi

# Copy SSH keys
log_info "Copying SSH keys from $SSH_SOURCE_DIR to $SSH_TARGET_DIR..."

# Check if files exist before copying
files_to_copy=("id_rsa" "id_rsa.pub" "known_hosts" "known_hosts.old")
copied_files=()

for file in "${files_to_copy[@]}"; do
    if [ -f "$SSH_SOURCE_DIR/$file" ]; then
        sudo cp "$SSH_SOURCE_DIR/$file" "$SSH_TARGET_DIR/"
        copied_files+=("$file")
        log_info "Copied: $file"
    else
        log_warning "File not found: $file (skipping)"
    fi
done

if [ ${#copied_files[@]} -eq 0 ]; then
    log_error "No SSH files were copied!"
    exit 1
fi

# Set ownership
log_info "Setting ownership to $USER:$USER..."
sudo chown -R "$USER:$USER" "$SSH_TARGET_DIR"

# Set permissions
log_info "Setting proper permissions..."
sudo chmod 700 "$SSH_TARGET_DIR"

for file in "${copied_files[@]}"; do
    case "$file" in
        id_rsa|known_hosts|known_hosts.old)
            sudo chmod 600 "$SSH_TARGET_DIR/$file"
            log_info "Set 600 permissions for $file"
            ;;
        id_rsa.pub)
            sudo chmod 644 "$SSH_TARGET_DIR/$file"
            log_info "Set 644 permissions for $file"
            ;;
    esac
done

log_success "SSH keys copied and permissions set successfully!"
echo ""
echo "========================================================================"
echo "Summary:"
echo "  - Files copied: ${copied_files[*]}"
echo "  - Target directory: $SSH_TARGET_DIR"
echo "  - Permissions: 700 for directory, 600 for private keys, 644 for public keys"
if [ -d "$BACKUP_DIR" ]; then
    echo "  - Backup location: $BACKUP_DIR"
fi
echo "========================================================================"
