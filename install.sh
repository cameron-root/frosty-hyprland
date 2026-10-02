#!/usr/bin/env bash
# ==============================================================================
# ❄️ Frosty Hyprland — Automated Installation Script
# A to Z unattended setup for Arch Linux
# ==============================================================================

set -euo pipefail

# ── Color Definitions ─────────────────────────────────────────────────────────
BOLD="\033[1m"
GREEN="\033[38;2;40;200;64m"
CYAN="\033[38;2;88;166;255m"
BLUE="\033[38;2;56;139;253m"
PURPLE="\033[38;2;188;140;255m"
YELLOW="\033[38;2;254;188;46m"
RED="\033[38;2;255;95;86m"
RESET="\033[0m"

log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

log_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  ______ _____   ____   _____ _______ __     __
 |  ____|  __ \ / __ \ / ____|__   __|\ \   / /
 | |__  | |__) | |  | | (___    | |    \ \_/ / 
 |  __| |  _  /| |  | |\___ \   | |     \   /  
 | |    | | \ \| |__| |____) |  | |      | |   
 |_|    |_|  \_\\____/|_____/   |_|      |_|   
          HYPRLAND — LIQUID FROSTED GLASS
EOF
    echo -e "${RESET}"
    echo -e "${PURPLE}Automated A-to-Z Installer for Arch Linux${RESET}\n"
}

# ── 1. Initial Sanity Checks ──────────────────────────────────────────────────
log_banner

# A. Prevent running directly as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please DO NOT run this installer directly as root."
    echo "Run it as your regular user with sudo privileges: ./install.sh"
    exit 1
fi

# B. Verify Arch Linux distribution
if [ ! -f /etc/arch-release ]; then
    log_error "This installation script is designed exclusively for Arch Linux."
    echo "If you are using an Arch-based derivative (EndeavourOS, CachyOS), it should work,"
    echo "but /etc/arch-release was not detected."
    read -rp "Do you wish to force continue? (y/N): " force_continue
    if [[ ! "$force_continue" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# C. Internet connectivity check
log_info "Verifying internet connection..."
if ! ping -c 1 -W 3 archlinux.org &>/dev/null && ! curl -s --head --request GET https://archlinux.org | grep "200 OK" &>/dev/null; then
    log_error "No active internet connection detected. Please connect and retry."
    exit 1
fi
log_success "Internet connection verified."

# D. Sudo credential caching
log_info "Requesting sudo privileges for package installation..."
sudo -v
# Keep sudo alive in background
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null || true' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="$USER"
TARGET_HOME="$HOME"

# ── 2. System Update & Base Development Packages ──────────────────────────────
log_info "Updating package databases and ensuring base development packages..."
sudo pacman -Syu --needed --noconfirm base-devel git curl wget rsync jq bc socat inotify-tools tar sed

# ── 3. Check / Install AUR Helper (yay) ────────────────────────────────────────
log_info "Checking for an AUR helper (yay or paru)..."
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
else
    log_warn "No AUR helper found. Bootstrapping 'yay-bin'..."
    YAY_TMP=$(mktemp -d /tmp/yay-bin.XXXXXX)
    git clone https://aur.archlinux.org/yay-bin.git "$YAY_TMP"
    (
        cd "$YAY_TMP"
        makepkg -si --noconfirm
    )
    rm -rf "$YAY_TMP"
    AUR_HELPER="yay"
fi
log_success "AUR helper ready: $AUR_HELPER"

# ── 4. Installing System Packages ─────────────────────────────────────────────
log_info "Installing official repository dependencies via pacman..."

PACMAN_PACKAGES=(
    # Hyprland Core & Ecosystem
    hyprland
    hypridle
    hyprlock
    hyprpaper
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt6-wayland
    qt5-wayland
    
    # Sound & Audio Stack
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pamixer
    playerctl
    pavucontrol
    cava
    
    # Display, Brightness & Hardware Controls
    brightnessctl
    upower
    libspng
    
    # Utilities & Terminal
    kitty
    starship
    fastfetch
    rofi
    wl-clipboard
    cliphist
    
    # Networking & Bluetooth
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    
    # GTK / Qt / Nautilus Theming
    nautilus
    ffmpegthumbnailer
    nwg-look
    qt5ct
    qt6ct
    kvantum
    papirus-icon-theme
)

sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

log_info "Installing AUR dependencies (Caelestia shell, Wallust, fonts, cursor)..."
AUR_PACKAGES=(
    quickshell
    bibata-cursor-theme
    ttf-jetbrains-mono-nerd
    ttf-victor-mono
    wallust
    awww
)

$AUR_HELPER -S --needed --noconfirm "${AUR_PACKAGES[@]}"

# ── 5. Backup Existing Configurations ─────────────────────────────────────────
BACKUP_DIR="$TARGET_HOME/.config/frosty_backup_$(date +%Y%m%d_%H%M%S)"
log_info "Creating backup of existing dotfiles if present to $BACKUP_DIR..."

DIRS_TO_BACKUP=(hypr caelestia kitty ghostty gtk-3.0 gtk-4.0 Kvantum qt5ct qt6ct cava rofi)
HAS_BACKUP=false
for d in "${DIRS_TO_BACKUP[@]}"; do
    if [ -d "$TARGET_HOME/.config/$d" ]; then
        if [ "$HAS_BACKUP" = false ]; then
            mkdir -p "$BACKUP_DIR"
            HAS_BACKUP=true
        fi
        cp -a "$TARGET_HOME/.config/$d" "$BACKUP_DIR/"
    fi
done

if [ -f "$TARGET_HOME/.config/starship.toml" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$TARGET_HOME/.config/starship.toml" "$BACKUP_DIR/"
fi

if [ "$HAS_BACKUP" = true ]; then
    log_success "Existing configuration backed up to $BACKUP_DIR"
else
    log_info "No conflicting configurations found. Fresh deployment ready."
fi

# ── 6. Deploy Dotfiles and Bundled Assets ──────────────────────────────────────
log_info "Deploying Frosty Hyprland configuration files..."

# A. ~/.config
mkdir -p "$TARGET_HOME/.config"
cp -r "$SCRIPT_DIR/configs/"* "$TARGET_HOME/.config/"

# Fix home paths in qt configs and hyprpaper
sed -i "s|/home/[^/]*|$TARGET_HOME|g" "$TARGET_HOME/.config/qt5ct/qt5ct.conf" 2>/dev/null || true
sed -i "s|/home/[^/]*|$TARGET_HOME|g" "$TARGET_HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null || true
sed -i "s|/home/[^/]*|$TARGET_HOME|g" "$TARGET_HOME/.config/hypr/hyprpaper.conf" 2>/dev/null || true

# Generate GTK bookmarks
mkdir -p "$TARGET_HOME/.config/gtk-3.0"
cat <<EOF > "$TARGET_HOME/.config/gtk-3.0/bookmarks"
file://$TARGET_HOME/Documents
file://$TARGET_HOME/Music
file://$TARGET_HOME/Pictures
file://$TARGET_HOME/Videos
file://$TARGET_HOME/Downloads
EOF

# B. ~/.local/bin
log_info "Installing executable helper scripts to ~/.local/bin..."
mkdir -p "$TARGET_HOME/.local/bin"
cp -r "$SCRIPT_DIR/local_bin/"* "$TARGET_HOME/.local/bin/"
chmod +x "$TARGET_HOME/.local/bin/"*

# Ensure hypr scripts are executable
chmod +x "$TARGET_HOME/.config/hypr/scripts/"*.sh "$TARGET_HOME/.config/hypr/UserScripts/"*.sh 2>/dev/null || true
ln -sf "$TARGET_HOME/.config/hypr/scripts/SetAccent.sh" "$TARGET_HOME/.config/hypr/UserScripts/SetAccent.sh" 2>/dev/null || true

# C. ~/.local/lib (Qt6 Caelestia Plugins & M3Shapes)
log_info "Deploying pre-compiled Qt6 plugins to ~/.local/lib..."
mkdir -p "$TARGET_HOME/.local/lib"
cp -r "$SCRIPT_DIR/local_lib/"* "$TARGET_HOME/.local/lib/"

# D. ~/.local/share (Caelestia color schemes)
log_info "Deploying Caelestia schemes to ~/.local/share/caelestia..."
mkdir -p "$TARGET_HOME/.local/share"
cp -r "$SCRIPT_DIR/local_share/"* "$TARGET_HOME/.local/share/"

# E. ~/.local/etc/xdg/quickshell (Caelestia desktop shell)
log_info "Deploying Quickshell Caelestia shell module..."
mkdir -p "$TARGET_HOME/.local/etc/xdg/quickshell"
cp -r "$SCRIPT_DIR/quickshell/"* "$TARGET_HOME/.local/etc/xdg/quickshell/"

# F. Wallpapers
log_info "Deploying Frosty wallpapers to ~/Pictures/wallpapers..."
mkdir -p "$TARGET_HOME/Pictures/wallpapers"
cp -r "$SCRIPT_DIR/wallpapers/"* "$TARGET_HOME/Pictures/wallpapers/"

# ── 7. System Services & Mime Configuration ───────────────────────────────────
log_info "Configuring system and user services..."

# Enable system network & bluetooth services
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true

# User systemd units
mkdir -p "$TARGET_HOME/.config/systemd/user"
cp -f "$SCRIPT_DIR/configs/systemd/user/caelestia-shell.service" "$TARGET_HOME/.config/systemd/user/"
systemctl --user daemon-reload 2>/dev/null || true

# Mask conflicting notification / status bar daemons
log_info "Masking conflicting services (waybar, swaync) to grant priority to Caelestia..."
systemctl --user mask waybar.service swaync.service 2>/dev/null || true

# Enable Caelestia Shell service
systemctl --user enable caelestia-shell.service 2>/dev/null || true

# Default file manager (Nautilus)
xdg-mime default org.gnome.Nautilus.desktop inode/directory 2>/dev/null || true

# Set dark theme, Papirus icons, and Bibata cursor
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

# ── 8. Shell Environment & PATH Setup ─────────────────────────────────────────
log_info "Configuring shell profiles (~/.bashrc, ~/.zshrc)..."

SHELL_RC_FILES=("$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc")
for rc in "${SHELL_RC_FILES[@]}"; do
    if [ -f "$rc" ] || [ "$(basename "$rc")" = ".bashrc" ]; then
        touch "$rc"
        # Export PATH
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
            echo -e '\n# Frosty Hyprland Environment' >> "$rc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        fi
        # Starship prompt
        if ! grep -q 'starship init' "$rc"; then
            SHELL_NAME=$(basename "$rc" | sed 's/\.//; s/rc//')
            echo "eval \"\$(starship init $SHELL_NAME)\"" >> "$rc"
        fi
    fi
done

# ── 9. Initial Theme Generation & Snapshot Creation ───────────────────────────
log_info "Initializing Frosty accent color (Blue / Frost)..."
bash "$TARGET_HOME/.config/hypr/scripts/SetAccent.sh" blue 2>/dev/null || true

log_info "Generating persistent baseline snapshot in ~/.snapshots/frosty-hyprland..."
bash "$TARGET_HOME/.local/bin/frosty-backup" baseline 2>/dev/null || true

# ── 10. Completed ─────────────────────────────────────────────────────────────
echo ""
log_success "❄️ Frosty Hyprland has been successfully installed!"
echo ""
echo -e "${CYAN}${BOLD}Summary of What Was Installed:${RESET}"
echo -e "  • ${BOLD}Hyprland & Ecosystem:${RESET} Side-by-side tiling, 18px radius, dual-pass glass blur"
echo -e "  • ${BOLD}Caelestia Desktop Shell:${RESET} Top dashboard, decoupled Quick Toggles & Notification Center"
echo -e "  • ${BOLD}Frosty Settings App:${RESET} Super+I or Super+, (6 accent themes, blur & opacity sliders)"
echo -e "  • ${BOLD}Liquid Frosted Nautilus:${RESET} Libadwaita & GTK4 rounded glass styling"
echo -e "  • ${BOLD}Terminals & Shell:${RESET} Kitty & Ghostty glass profiles + Starship prompt"
echo -e "  • ${BOLD}Persistent Snapshots:${RESET} Automatic backup & restore tools (~/.snapshots/)"
echo ""
echo -e "${YELLOW}${BOLD}How to Start:${RESET}"
echo -e "  1. If you are in a TTY, simply run:  ${CYAN}Hyprland${RESET}"
echo -e "  2. If you are in a Display Manager (SDDM/GDM), select '${CYAN}Hyprland${RESET}' and log in."
echo -e "  3. Recommended: reboot your system to apply all user systemd services and groups."
echo ""
read -rp "Would you like to reboot now? (y/N): " do_reboot
if [[ "$do_reboot" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
