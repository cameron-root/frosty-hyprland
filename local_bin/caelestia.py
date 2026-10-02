#!/usr/bin/env python3
"""
Caelestia CLI wrapper for managing Caelestia Shell, wallpapers, schemes, and IPC toggles.
"""

import sys
import os
import json
import random
import subprocess
from pathlib import Path

HOME = Path.home()
STATE_DIR = HOME / ".local/state/caelestia"
SCHEMES_DIR = HOME / ".local/share/caelestia/schemes"
WALLPAPERS_DIR = Path(os.environ.get("CAELESTIA_WALLPAPERS_DIR", HOME / "Pictures/wallpapers"))
WALLPAPER_STATE = STATE_DIR / "wallpaper/path.txt"
SCHEME_STATE = STATE_DIR / "scheme.json"

def qs_ipc(target, func, *args):
    cmd = ["qs", "-c", "caelestia", "ipc", "call", target, func, *args]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return res.stdout.strip()
    except Exception as e:
        return ""

def cmd_toggle(drawer, *args):
    if drawer == "nexus":
        page = args[0] if args else ""
        qs_ipc("nexus", "open", page)
    else:
        qs_ipc("drawers", "toggle", drawer)

def cmd_toast(toast_type, title, message, icon="spark"):
    func = toast_type if toast_type in ["info", "success", "warn", "error"] else "info"
    qs_ipc("toaster", func, title, message, icon)

def get_current_scheme():
    try:
        return json.loads(SCHEME_STATE.read_text())
    except Exception:
        return {"name": "caelestia", "flavour": "default", "mode": "dark"}

def set_scheme(name, flavour=None, mode=None):
    scheme_folder = SCHEMES_DIR / name
    if not scheme_folder.exists():
        print(f"Unknown scheme '{name}'. Available: {', '.join(sorted(os.listdir(SCHEMES_DIR)))}")
        return

    flavours = [f.name for f in scheme_folder.iterdir() if f.is_dir()]
    if not flavours:
        return
    chosen_flavour = flavour if flavour in flavours else flavours[0]

    flavour_folder = scheme_folder / chosen_flavour
    modes = [f.stem for f in flavour_folder.iterdir() if f.is_file() and f.suffix == ".txt"]
    chosen_mode = mode if mode in modes else ("dark" if "dark" in modes else modes[0])

    txt_file = flavour_folder / f"{chosen_mode}.txt"
    if not txt_file.exists():
        print(f"Scheme variant {txt_file} not found.")
        return

    colours = {
        k.strip(): v.strip().removeprefix('#')
        for k, v in (line.split(' ') for line in txt_file.read_text().splitlines() if line)
    }

    data = {
        "name": name,
        "flavour": chosen_flavour,
        "mode": chosen_mode,
        "variant": "tonalspot",
        "colours": colours
    }
    SCHEME_STATE.parent.mkdir(parents=True, exist_ok=True)
    SCHEME_STATE.write_text(json.dumps(data, indent=2))
    print(f"Applied scheme: {name} ({chosen_flavour} - {chosen_mode})")
    cmd_toast("success", "Theme Changed", f"{name.capitalize()} {chosen_flavour}", "palette")

def set_wallpaper_file(path_str):
    p = Path(path_str).resolve()
    if not p.exists():
        print(f"Wallpaper not found: {p}")
        return

    WALLPAPER_STATE.parent.mkdir(parents=True, exist_ok=True)
    WALLPAPER_STATE.write_text(str(p))

    # Apply wallpaper to swww and hyprpaper
    try:
        subprocess.run(["swww", "img", str(p), "--transition-type", "wipe", "--transition-angle", "30", "--transition-duration", "1.2"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass
    try:
        # Update hyprpaper
        subprocess.run(["hyprctl", "hyprpaper", "preload", str(p)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f"eDP-1,{p}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # Update wallust colors
    try:
        subprocess.run(["wallust", "run", str(p)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    print(f"Wallpaper set: {p.name}")

def cmd_wallpaper(args):
    if not args:
        if WALLPAPER_STATE.exists():
            print(WALLPAPER_STATE.read_text().strip())
        return

    if args[0] in ["-r", "--random"]:
        # Pick random
        valid_exts = {".png", ".jpg", ".jpeg", ".webp"}
        walls = [f for f in WALLPAPERS_DIR.glob("**/*") if f.suffix.lower() in valid_exts]
        if walls:
            chosen = random.choice(walls)
            set_wallpaper_file(str(chosen))
    elif args[0] in ["-f", "--file"]:
        if len(args) > 1:
            set_wallpaper_file(args[1])
    elif args[0] in ["-p", "--preview"]:
        # Preview scheme
        scheme = get_current_scheme()
        print(json.dumps(scheme))
    else:
        set_wallpaper_file(args[0])

def cmd_shell(args):
    if not args:
        subprocess.run(["systemctl", "--user", "restart", "caelestia-shell"])
        return
    flag = args[0]
    if flag in ["-k", "--kill"]:
        subprocess.run(["systemctl", "--user", "stop", "caelestia-shell"])
    elif flag in ["-r", "--restart"]:
        subprocess.run(["systemctl", "--user", "restart", "caelestia-shell"])
    elif flag in ["-l", "--log"]:
        subprocess.run(["journalctl", "--user", "-u", "caelestia-shell", "-f"])
    elif flag in ["-s", "--show"]:
        print(qs_ipc("drawers", "list"))

def main():
    if len(sys.argv) < 2:
        print("Usage: caelestia [toggle|wallpaper|scheme|nexus|launcher|dashboard|session|shell|toast] ...")
        sys.exit(0)

    cmd = sys.argv[1]
    args = sys.argv[2:]

    if cmd == "toggle":
        drawer = args[0] if args else "launcher"
        cmd_toggle(drawer, *args[1:])
    elif cmd in ["nexus", "launcher", "dashboard", "session", "sidebar", "utilities"]:
        cmd_toggle(cmd, *args)
    elif cmd == "wallpaper":
        cmd_wallpaper(args)
    elif cmd == "scheme":
        if not args or args[0] == "list":
            schemes = sorted([f.name for f in SCHEMES_DIR.iterdir() if f.is_dir()])
            curr = get_current_scheme()
            print(f"Current scheme: {curr.get('name')} ({curr.get('flavour')} {curr.get('mode')})")
            print(f"Available schemes: {', '.join(schemes)}")
        elif args[0] == "get":
            print(json.dumps(get_current_scheme(), indent=2))
        else:
            name = args[0]
            flavour = args[1] if len(args) > 1 else None
            mode = args[2] if len(args) > 2 else None
            set_scheme(name, flavour, mode)
    elif cmd == "toast":
        ttype = args[0] if len(args) > 0 else "info"
        title = args[1] if len(args) > 1 else "Caelestia"
        msg = args[2] if len(args) > 2 else ""
        icon = args[3] if len(args) > 3 else "spark"
        cmd_toast(ttype, title, msg, icon)
    elif cmd == "shell":
        cmd_shell(args)
    else:
        print(f"Unknown command: {cmd}")

if __name__ == "__main__":
    main()
