# ❄️ Frosty Hyprland — Liquid Frosted Glass Desktop

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-00aaee?style=for-the-badge&logo=wayland&logoColor=white)](https://hyprland.org)
[![Wayland](https://img.shields.io/badge/Wayland-blue?style=for-the-badge)](https://wayland.freedesktop.org/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt6_QML-purple?style=for-the-badge)](https://git.outfoxxed.me/outfoxxed/quickshell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> A high-performance, iOS Liquid Frosted Glass desktop environment for Arch Linux. Powered by **Hyprland**, the **Caelestia Desktop Shell** (Qt6/Quickshell), **Libadwaita/GTK4 Frosted Glass Nautilus**, and a native **6-accent dynamic theme engine**.

---

## ✨ Features

- **Liquid Frosted Glass Aesthetic:** Dual-pass hardware blur (passes: 2, size: 8, vibrancy: 0.22, contrast: 1.15) with subtle luminous borders (`rgba(255,255,255,0.18)`).
- **Caelestia Desktop Shell:**
  - **Decoupled Quick Toggles & Notification Center:** A dedicated top-right trigger for detailed system toggles (WiFi, Bluetooth, Night Light, Performance, Settings) and a separate right-side sliding Notification Drawer.
  - **Top Dashboard:** Dynamic workspaces, clock, active window switch indicator, media player, and system tray.
  - **Frosty Settings Page:** Integrated into Caelestia Nexus (`Super + I` or `Super + ,`) with live sliders for blur size, blur passes, corner radius, window opacity, and gaps.
- **6 Dynamic Accent Themes:** Switch instantaneously between **Frost Blue**, **Emerald Green**, **Titanium Grey**, **Amethyst Purple**, **Coral Pink**, and **Amber Gold** across Hyprland, GTK, Cava, and Caelestia without needing to restart.
- **Natural Side-by-Side Tiling:** Clean horizontal left/right window splitting (`force_split = 2`, `split_width_multiplier = 1.5`).
- **Liquid Glass Nautilus (GNOME Files):** Complete Libadwaita & GTK4 frosted glass theme matching the system theme with transcluent sidebars, capsule buttons, and floating viewports.
- **Terminals & Shell:**
  - **Kitty & Ghostty:** Translucent blurred backdrops with matching iOS glass color palettes.
  - **Starship Prompt:** Fast, informative prompt showing directory, git status, and execution timings.
- **Persistent Baseline Snapshots:** Instant one-click configuration backup and restore tools (`frosty-backup`, `frosty-restore`) that keep your desktop persistent across reboots and experiments.

---

## 🚀 One-Line Automated Installation

On a fresh installation of **Arch Linux** (or an Arch-based distribution), simply clone this repository and run the unattended installer:

```bash
git clone https://github.com/cameron-root/frosty-hyprland.git
cd frosty-hyprland
chmod +x install.sh
./install.sh
```

### What `install.sh` Does Automatically:
1. Verifies Arch Linux and checks internet connectivity.
2. Prompts for `sudo` once and maintains credentials in the background.
3. Updates system packages and verifies `base-devel`, `git`, and build utilities.
4. Detects or automatically bootstraps `yay` (AUR helper).
5. Installs all required pacman and AUR dependencies (Hyprland, Caelestia, Pipewire, Nautilus, fonts, themes, cursors).
6. Backs up any existing configuration files into `~/.config/frosty_backup_<timestamp>/`.
7. Deploys all dotfiles, pre-compiled Qt6 Caelestia QML plugins, themes, and curated wallpapers.
8. Configures systemd services, enables `caelestia-shell.service`, and masks conflicting status bars (`waybar`, `swaync`).
9. Configures shell profiles (`.bashrc` / `.zshrc`) with PATH and Starship prompt.
10. Generates the default theme cache and creates an initial persistent snapshot in `~/.snapshots/`.

---

## ⌨️ Default Keybindings Cheatsheet

| Keybinding | Action | Description |
| :--- | :--- | :--- |
| **`Super + Q`** | Launch Terminal | Opens Kitty terminal with frosted glass styling |
| **`Super + E`** | Open File Manager | Opens Nautilus with Libadwaita Liquid Glass theme |
| **`Super + Space`** | Application Launcher | Opens Rofi application drawer |
| **`Super + I`** or **`Super + ,`** | **Frosty Settings** | Opens the Frosty Hyprland Control Center |
| **`Super + V`** | Clipboard Manager | Opens Rofi clipboard history picker |
| **`Super + C`** | Close Window | Closes the active window |
| **`Super + Shift + Space`** | Toggle Floating | Switches window between tiled and floating mode |
| **`Super + F`** | Toggle Fullscreen | Fullscreen active window |
| **`Super + W`** | Change Wallpaper | Sets a new random wallpaper with smooth wipe transition |
| **`Super + L`** | Lock Screen | Locks desktop with iOS frosted glass Hyprlock |
| **`Super + Shift + S`** | Take Screenshot | Interactive area screenshot saved to clipboard & pictures |
| **`Super + H / J / K / L`** | Focus Window | Move window focus Left, Down, Up, Right |
| **`Super + 1..9`** | Switch Workspace | Switch to workspace 1 through 9 |
| **`Super + Shift + 1..9`** | Move to Workspace | Move active window to workspace 1 through 9 |
| **`XF86AudioMute`** | Toggle Audio Mute | Mute/unmute Pipewire audio |
| **`XF86AudioRaiseVolume`** | Volume Up | Raise volume by 5% with OSD popup |
| **`XF86AudioLowerVolume`** | Volume Down | Lower volume by 5% with OSD popup |
| **`XF86MonBrightnessUp`** | Brightness Up | Raise screen brightness by 5% with OSD popup |
| **`XF86MonBrightnessDown`** | Brightness Down | Lower screen brightness by 5% with OSD popup |

---

## 🎨 Theme & Customization

### Changing Accent Color
You can switch your accent theme anytime:
1. Open Frosty Settings via **`Super + I`**.
2. Select any accent chip (**Frost Blue**, **Emerald Green**, **Titanium Grey**, **Amethyst Purple**, **Coral Pink**, **Amber Gold**).
3. All GTK applications, Hyprland borders, and Caelestia widgets will immediately adapt to your chosen color palette.

Alternatively, you can run from your terminal:
```bash
~/.config/hypr/scripts/SetAccent.sh green   # or blue, grey, purple, pink, yellow
```

### Snapshot & State Management
- **Take Snapshot:** Save your current desktop configuration:
  ```bash
  frosty-backup my-custom-setup
  ```
- **Restore Snapshot:** Restore your baseline setup anytime:
  ```bash
  frosty-restore
  ```

---

## 🛠️ Repository File Structure

```
frosty-hyprland/
├── install.sh                  # Unattended A-to-Z installer
├── README.md                   # Documentation and keybindings
├── .gitignore                  # Git ignore rules
├── configs/                    # System and application dotfiles
│   ├── hypr/                   # Hyprland window manager configurations
│   ├── caelestia/              # Caelestia shell preferences
│   ├── kitty/                  # Kitty terminal configuration
│   ├── ghostty/                # Ghostty terminal configuration
│   ├── gtk-3.0/                # GTK3 Frosted Glass theme & CSS
│   ├── gtk-4.0/                # GTK4 & Libadwaita Nautilus Frosted CSS
│   ├── Kvantum/                # Kvantum Qt SVG styling
│   ├── qt5ct/                  # Qt5 font and styling configuration
│   ├── qt6ct/                  # Qt6 font and styling configuration
│   ├── cava/                   # Cava audio visualizer configuration
│   ├── rofi/                   # Rofi app launcher and clipboard theme
│   ├── starship.toml           # Starship shell prompt configuration
│   └── systemd/                # User systemd units (caelestia-shell.service)
├── local_bin/                  # Helper binaries and custom CLI tools
│   ├── caelestia               # Caelestia Shell CLI controller
│   ├── caelestia-shell         # Caelestia Quickshell launcher
│   ├── frosty-settings         # Frosty Control Center application
│   ├── frosty-backup           # Configuration snapshot backup script
│   └── frosty-restore          # Configuration snapshot restore script
├── local_lib/                  # Pre-compiled Qt6 plugins (M3Shapes, cava)
├── local_share/                # Caelestia color schemes
├── quickshell/                 # Full Quickshell QML Caelestia desktop module
└── wallpapers/                 # Curated starter wallpapers
```

---

## 🌐 Pushing to Your GitHub Repository

To host this repository on your GitHub account, follow these steps:

### Step 1: Create a New Repository on GitHub
1. Log in to [GitHub](https://github.com).
2. Click **New repository** (or navigate to `https://github.com/new`).
3. Name it **`frosty-hyprland`**.
4. Leave it empty (do **not** initialize with README or .gitignore, as we already have them).
5. Click **Create repository**.

### Step 2: Push from Your Terminal
On your machine, open terminal in `~/frosty-hyprland`:

```bash
cd ~/frosty-hyprland

# Initialize git if not already initialized
git init

# Add all files
git add .

# Create the initial commit
git commit -m "feat: initial commit of Frosty Hyprland Liquid Glass Desktop"

# Rename default branch to main
git branch -M main

# Add your GitHub remote URL
git remote add origin https://github.com/cameron-root/frosty-hyprland.git

# Push to GitHub
git push -u origin main
```

*(Note: When prompted for password by GitHub, use a [Personal Access Token (classic)](https://github.com/settings/tokens) with `repo` scope, or use SSH keys if configured).*

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
Designed with ❤️ for Arch Linux and Hyprland enthusiasts.
