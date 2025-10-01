#!/bin/bash
# Arch BSPWM Full Setup Script
# Run as your normal user (not root) after base install
# Usage: chmod +x arch_bspwm_setup.sh && ./arch_bspwm_setup.sh

set -e

# --- Variables ---
DOTFILES_REPO="https://github.com/JustIbis/bspwm-dotfiles-ibis.git"
CONFIG_DIR="$HOME/.config"

# --- Update system ---
echo "Updating system..."
sudo pacman -Syu --noconfirm

# --- Install core packages ---
echo "Installing core packages..."
sudo pacman -S --needed --noconfirm \
    bspwm sxhkd picom-ibhagwan feh polybar rofi kitty \
    brightnessctl flameshot gnome-settings-daemon \
    gnome-control-center gnome-tweaks gnome-keyring \
    dunst git base-devel xorg xorg-xinit xorg-xrandr \
    xclip xdg-utils wget curl

# --- NVIDIA proprietary drivers ---
echo "Installing NVIDIA drivers..."
sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings

# --- Fonts & Icons ---
sudo pacman -S --needed --noconfirm ttf-jetbrains-mono papirus-icon-theme

# --- Python & wpgtk/pywal ---
sudo pacman -S --needed --noconfirm python-pywal python-pip
pip install --user wpgtk

# --- Clone dotfiles ---
echo "Cloning dotfiles..."
if [ ! -d "$HOME/dotfiles" ]; then
    git clone "$DOTFILES_REPO" "$HOME/dotfiles"
else
    echo "Dotfiles already cloned, pulling latest..."
    cd "$HOME/dotfiles" && git pull
fi

# --- Create config directories ---
mkdir -p $CONFIG_DIR/bspwm $CONFIG_DIR/sxhkd $CONFIG_DIR/polybar $CONFIG_DIR/rofi $CONFIG_DIR/picom

# --- Symlink dotfiles ---
echo "Symlinking dotfiles..."
ln -sf "$HOME/dotfiles/bspwm/bspwmrc" "$CONFIG_DIR/bspwm/bspwmrc"
ln -sf "$HOME/dotfiles/sxhkd/sxhkdrc" "$CONFIG_DIR/sxhkd/sxhkdrc"
ln -sf "$HOME/dotfiles/polybar/config.ini" "$CONFIG_DIR/polybar/config.ini"
ln -sf "$HOME/dotfiles/polybar/launch.sh" "$CONFIG_DIR/polybar/launch.sh"
ln -sf "$HOME/dotfiles/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi"
ln -sf "$HOME/dotfiles/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf"

# Make polybar launch script executable
chmod +x "$CONFIG_DIR/polybar/launch.sh"

# --- Enable required services ---
echo "Enabling required services..."
systemctl --user enable gnome-keyring-daemon.service
systemctl --user start gnome-keyring-daemon.service

# --- NVIDIA settings for ForceFullCompositionPipeline ---
echo "Applying NVIDIA Full Composition Pipeline..."
nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 { ForceFullCompositionPipeline = On }"

# --- Optional: Set .xinitrc for startx ---
XINITRC="$HOME/.xinitrc"
if [ ! -f "$XINITRC" ]; then
    echo "Creating ~/.xinitrc..."
    cat <<'EOF' > "$XINITRC"
#!/bin/sh
# Load GNOME environment variables
export $(dbus-launch)
# Start bspwm
exec bspwm
EOF
    chmod +x "$XINITRC"
fi

echo "Setup complete! You can now run 'startx' to start bspwm."
