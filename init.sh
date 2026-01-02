#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting setup for Debian 13..."

# Update and Upgrade the system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install basic dependencies for the script
sudo apt install -y curl wget gpg apt-transport-https ca-certificates lsb-release

# 2. Install Git
echo "Installing Git..."
sudo apt install -y git

# Configure global Git identity
echo "Configuring Git global user..."
read -p "Do you want to configure Git global user now? (y/N) " response
if [[ "$response" =~ ^[yY](es)?$ ]]; then
    read -p "Enter your Git email address: " git_email
    if [ -n "$git_email" ]; then
        git config --global user.name "$USER"
        git config --global user.email "$git_email"
        echo "Git configured with user.name=$USER and user.email=$git_email"
    else
        echo "No email provided. Skipping Git global configuration."
    fi
fi

# 3. Install Google Chrome
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm -f google-chrome-stable_current_amd64.deb

# 4. Install Brave Browser
echo "Installing Brave Browser..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# 5. Install Zsh and Oh-My-Zsh
echo "Installing Zsh..."
sudo apt install -y zsh
# Set Zsh as default shell
sudo chsh -s "$(which zsh)" "$USER"

echo "Installing Oh-My-Zsh..."
# Check if Oh-My-Zsh is already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh-My-Zsh is already installed."
fi

# Configure Ohm-My-Zsh theme
read -p "Do you want to change the Oh-My-Zsh theme? (y/N) " response
if [[ "$response" =~ ^[yY](es)?$ ]]; then
    echo "Available themes: agnoster, robbyrussell, bira, ys, af-magic, gnzh, etc."
    read -p "Enter the theme name you want to use: " zsh_theme
    if grep -q "^ZSH_THEME=" "$HOME/.zshrc"; then
        sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$zsh_theme\"/" "$HOME/.zshrc"
        echo "Oh-My-Zsh theme set to $zsh_theme"
    else
        echo "ZSH_THEME=\"$zsh_theme\"" >> "$HOME/.zshrc"
        echo "Oh-My-Zsh theme set to $zsh_theme"
    fi
fi

# 6 & 7. Install Norminette and Flake8
# Using pipx is recommended on Debian 12+ (and 13) to avoid conflicts with system python
echo "Installing Python tools (Norminette, Flake8)..."
sudo apt install -y python3-pip python3-venv pipx
pipx ensurepath
pipx install norminette
pipx install flake8

# 8. Install NPM (Node.js)
echo "Installing NPM..."
sudo apt install -y nodejs npm

# 9. Install VS Code
if command -v code >/dev/null 2>&1; then
    echo "VS Code is already installed. Skipping installation."
else
    echo "Installing VS Code..."

    # Check if VS Code repo is already configured with the 'other' key (User's existing config)
    # The error indicates a conflict with /usr/share/keyrings/microsoft.gpg
    if grep -r "packages.microsoft.com/repos/code" /etc/apt/sources.list /etc/apt/sources.list.d/ | grep "microsoft.gpg"; then
        echo "Detected existing VS Code configuration. Removing script-generated config to resolve conflicts..."
        # If we previously created this file and it conflicts, remove it to favor the existing config
        if [ -f "/etc/apt/sources.list.d/vscode.list" ]; then
             # Check if vscode.list is the one causing conflict (i.e. it uses the script's key path)
             if grep -q "/etc/apt/keyrings/packages.microsoft.gpg" "/etc/apt/sources.list.d/vscode.list"; then
                echo "Removing conflicting /etc/apt/sources.list.d/vscode.list..."
                sudo rm -f "/etc/apt/sources.list.d/vscode.list"
             fi
        fi
    else
        # No existing config detected, proceed with standard setup
        echo "Configuring VS Code repository..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg
    fi

    sudo apt update
    sudo apt install -y code
fi

# 10. Install Docker and add user to docker group
echo "Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
# Note: If 'trixie' (Debian 13) repo is not yet available, you might need to fallback to 'bookworm'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

# 11. Install C/C++ environment
echo "Installing C/C++ build essentials..."
sudo apt install -y build-essential gdb cmake valgrind

echo "----------------------------------------------------------------"
echo "Installation complete!"
echo "It is recommended to restart your computer to apply all changes (groups, shell, etc.)."
echo "----------------------------------------------------------------"

read -p "Do you want to reboot now? (y/N) " response
if [[ "$response" =~ ^[yY](es)?$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Please remember to reboot or log out/in later."
fi
