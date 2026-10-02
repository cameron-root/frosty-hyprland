#!/usr/bin/env python3
import sys
import re
import os

def normalize_combo(combo):
    return combo.replace(" ", "").replace("\t", "")

def extract_combo(line):
    # Remove comments and whitespace
    line = re.sub(r'\s*#.*$', '', line).strip()
    
    if '=' not in line:
        return None
        
    try:
        rhs = line.split('=', 1)[1]
        parts = [p.strip() for p in rhs.split(',')]
        if len(parts) < 2:
            return None
            
        mods = parts[0]
        key = parts[1]
        return f"{mods},{key}"
    except Exception:
        return None

def parse_files(files):
    # Data structures to match original logic
    binding_map = {}        # combo -> effective line
    source_map = {}         # combo -> source file
    user_bind_map = {}      # combo -> user bind line
    unbound_user = {}       # combo -> True if explicitly unbound in user file
    seen_any_bind = {}      # combo -> True if seen
    default_seen = {}       # combo -> True if default bind exists
    
    # We assume the last file in the list is the user config (UserKeybinds.conf)
    # This matches the bash script logic where user_keybinds_conf is passed last
    if not files:
        return [], []
        
    user_conf_path = files[-1] if len(files) > 1 else None

    for file_path in files:
        if not os.path.exists(file_path):
            continue
            
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                for line in f:
                    line = line.rstrip('\n')
                    if not line or line.strip().startswith('#'):
                        continue
                        
                    is_bind = re.match(r'^\s*bind[a-z]*\s*=', line)
                    is_unbind = re.match(r'^\s*unbind\s*=', line)
                    
                    if is_bind:
                        combo_raw = extract_combo(line)
                        if not combo_raw:
                            continue
                        combo = normalize_combo(combo_raw)
                        seen_any_bind[combo] = True
                        
                        is_user_file = (file_path == user_conf_path)
                        
                        if not is_user_file:
                            default_seen[combo] = True
                            
                        # prefer user bind, else first seen
                        if combo not in source_map:
                            binding_map[combo] = line
                            source_map[combo] = file_path
                            
                        if is_user_file:
                            user_bind_map[combo] = line
                            binding_map[combo] = line
                            source_map[combo] = file_path
                            
                    elif is_unbind:
                        combo_raw = extract_combo(line)
                        if not combo_raw:
                            continue
                        combo = normalize_combo(combo_raw)
                        
                        if file_path == user_conf_path:
                            unbound_user[combo] = True
                            
                        # If unbind is found, we should remove the bind from our map
                        # so it doesn't show up in the menu.
                        if combo in binding_map:
                            del binding_map[combo]
                        if combo in source_map:
                            del source_map[combo]
                            
        except Exception as e:
            # Silently ignore read errors to mimic bash behavior or log to stderr
            sys.stderr.write(f"Error reading {file_path}: {e}\n")
            continue

    # Build results
    raw_keybinds = []
    missing_unbind_suggestions = []
    
    for combo in seen_any_bind:
        eff_line = binding_map.get(combo)
        src = source_map.get(combo)
        
        if not eff_line:
            continue
            
        raw_keybinds.append(eff_line)
        
        # Check for missing unbind suggestions
        # If user overrides a default but didn't unbind in user file
        if (src == user_conf_path and 
            combo in default_seen and 
            combo not in unbound_user):
            
            # Create suggestion: replace 'bind' with 'unbind'
            suggest = re.sub(r'^\s*bind[a-z]*', 'unbind', eff_line)
            missing_unbind_suggestions.append(suggest)
            
    return raw_keybinds, missing_unbind_suggestions

def detect_category(combo, desc, dispatcher, params):
    text = f"{combo} {desc} {dispatcher} {params}".lower()
    if "caelestia" in text:
        return "[Caelestia]"
    elif any(k in text for k in ["screenshot", "grim", "slurp", "swappy", "print"]):
        return "[Screenshot]"
    elif any(k in text for k in ["terminal", "kitty", "browser", "thunar", "file manager", "drun", "music", "calc"]):
        return "[Apps]"
    elif any(k in text for k in ["workspace", "movetoworkspace"]):
        return "[Workspaces]"
    elif any(k in text for k in ["volume", "audio", "mic", "brightness", "hyprsunset", "mute", "playerctl"]):
        return "[Media & HW]"
    elif any(k in text for k in ["fullscreen", "float", "kill", "close", "focus", "movewindow", "resizewindow", "split", "layout", "pin", "dwindle", "master", "zoom"]):
        return "[Window]"
    elif any(k in text for k in ["lock", "power", "exit", "suspend", "session", "clipboard", "cliphist", "gamemode", "blur", "theme", "refresh"]):
        return "[System]"
    elif any(k in text for k in ["keybind", "cheat", "help"]):
        return "[Help]"
    return "[General]"

def format_for_rofi(raw_binds):
    import json
    formatted_lines = []
    exec_map = {}
    
    cat_priority = {
        "[Caelestia]": 0,
        "[Apps]": 1,
        "[Window]": 2,
        "[Workspaces]": 3,
        "[Screenshot]": 4,
        "[Media & HW]": 5,
        "[System]": 6,
        "[Help]": 7,
        "[General]": 8,
    }
    
    items = []
    
    for line in raw_binds:
        match = re.match(r'^\s*(bind[a-z]*)\s*=(.*)', line)
        if not match:
            continue
            
        binder = match.group(1).replace(" ", "").replace("\t", "")
        rhs = match.group(2).strip()
        
        has_desc = 'd' in binder and binder != 'bind'

        parts = [p.strip() for p in rhs.split(',')]
        if len(parts) < 2:
            continue
            
        mods = parts[0]
        key = parts[1]
        
        desc = ""
        dispatcher = ""
        params = ""
        start_idx = 0
        
        if has_desc:
            desc = parts[2] if len(parts) >= 3 else ""
            dispatcher = parts[3] if len(parts) >= 4 else ""
            start_idx = 4
        else:
            dispatcher = parts[2] if len(parts) >= 3 else ""
            start_idx = 3
            
        remaining_parts = []
        if start_idx < len(parts):
            for i in range(start_idx, len(parts)):
                if parts[i]:
                    remaining_parts.append(parts[i])
        
        if remaining_parts:
            params = ", ".join(remaining_parts)
            
        # Formatting mods
        mods = mods.replace("$mainMod", "SUPER")
        mods = re.sub(r'[ \t]+', ' + ', mods.strip())
        
        if mods and key:
            combo_str = f"{mods} + {key}"
        elif key:
            combo_str = key
        else:
            combo_str = mods
            
        category = detect_category(combo_str, desc, dispatcher, params)
        
        if has_desc and desc:
            if params:
                clean_param = params.replace("$HOME", "~").replace("$scriptsDir", "scripts").replace("$UserScripts", "scripts")
                line_str = f"{category:<14}  {combo_str:<24}  ➜  {desc:<32}  ❨{clean_param}❩"
            else:
                line_str = f"{category:<14}  {combo_str:<24}  ➜  {desc}"
        elif dispatcher:
            if params:
                line_str = f"{category:<14}  {combo_str:<24}  ➜  {dispatcher} {params}"
            else:
                line_str = f"{category:<14}  {combo_str:<24}  ➜  {dispatcher}"
        else:
            line_str = f"{category:<14}  {combo_str}"
            
        items.append((cat_priority.get(category, 99), category, line_str, dispatcher, params, desc or combo_str))
        
    items.sort(key=lambda x: (x[0], x[1], x[2]))
    
    for _, _, line_str, dispatcher, params, desc in items:
        formatted_lines.append(line_str)
        exec_map[line_str] = {
            "dispatcher": dispatcher,
            "params": params,
            "desc": desc
        }
        
    try:
        with open("/tmp/hypr_keybinds_exec.json", "w") as f:
            json.dump(exec_map, f, indent=2)
    except Exception:
        pass
        
    return formatted_lines

def main():
    if len(sys.argv) < 2:
        # No files provided
        sys.exit(0)
        
    config_files = sys.argv[1:]
    
    binds, suggestions = parse_files(config_files)
    
    if not binds:
        print("no keybinds found.")
        sys.exit(1)
        
    formatted = format_for_rofi(binds)
    
    for line in formatted:
        print(line)
        
    # Handle suggestions (print to stderr or a specific file if needed, 
    # but the original script assigns it to a variable 'msg'.
    # To pass this back to bash, we might need a separate mechanism or just print to a known file.)
    if suggestions:
        import tempfile
        try:
            with tempfile.NamedTemporaryFile(mode='w', delete=False, prefix='hypr-unbind-suggestions-', suffix='.conf') as tf:
                tf.write('\n'.join(suggestions) + '\n')
                # We print a special marker line to stdout that the bash script can capture?
                # Or better, just print to stderr and let the user ignore it, 
                # OR, since the original script specifically puts it in the Rofi message,
                # we can print a special string at the END of stdout or to a side channel.
                
                # Let's decide to print the valid keybinds to stdout (for rofi).
                # And print the suggestion file path to a known location or specific fd if possible.
                # Simplest: Write to a fixed temp file location that the bash script checks.
                with open("/tmp/hypr_keybind_suggestions_file", "w") as sf:
                    sf.write(tf.name)
        except Exception:
            pass

if __name__ == "__main__":
    main()
