# Project: KeaTUI (Modular Edition)
# Files: main.py (entrypoint), ui.py (urwid-based UI), api.py (Control Agent interactions), config.py (persistent settings), installer.py (Kea install logic)

# main.py
import sys
import os
from ui import launch_ui
from config import init_config
from api import use_local_or_remote_api
from installer import check_or_install_kea

def main():
    init_config()
    exe_name = os.path.basename(sys.argv[0]).lower()

    if "local" in exe_name:
        api_url = "http://localhost:8000"
        mode = "local"
    elif "remote" in exe_name:
        url = input("Enter remote API URL (e.g., http://192.168.1.1:8000): ").strip()
        api_url = url
        mode = "remote"
    else:
        api_url, mode = use_local_or_remote_api()

    if mode == "local":
        check_or_install_kea()

    launch_ui(api_url)

if __name__ == "__main__":
    main()


# ui.py
import urwid

def launch_ui(api_url):
    body = [urwid.Text(f"Connected to: {api_url}"), urwid.Divider()]
    body.append(urwid.Button("Exit", on_press=lambda btn: raise_exit()))
    main_loop = urwid.MainLoop(urwid.ListBox(urwid.SimpleFocusListWalker(body)), handle_mouse=True)
    main_loop.run()

def raise_exit():
    raise urwid.ExitMainLoop()


# api.py
import os
import json
from config import SETTINGS_FILE, save_settings

def use_local_or_remote_api():
    print("--- KeaTUI Mode Selection ---")
    print("1. 🌐 Connect to remote Kea server")
    print("2. 🖥️  Use local Kea server")
    mode = input("Select mode [1-2]: ")

    if mode.strip() == "1":
        url = input("Enter remote API URL (e.g., http://192.168.1.1:8000): ").strip()
        connection_mode = "remote"
    else:
        url = "http://localhost:8000"
        connection_mode = "local"

    save_settings({"api_url": url})
    return url, connection_mode


# config.py
import os
import json

CONFIG_DIR = "/etc/kea-tui"
SETTINGS_FILE = os.path.join(CONFIG_DIR, "settings.json")

DEFAULTS = {
    "api_url": "http://localhost:8000"
}

def init_config():
    if not os.path.exists(CONFIG_DIR):
        os.makedirs(CONFIG_DIR, exist_ok=True)
    if not os.path.exists(SETTINGS_FILE):
        save_settings(DEFAULTS)

def load_settings():
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, "r") as f:
            return json.load(f)
    return DEFAULTS

def save_settings(data):
    with open(SETTINGS_FILE, "w") as f:
        json.dump(data, f, indent=2)


# installer.py
import os
import subprocess

def is_kea_installed():
    return os.path.exists("/etc/kea/kea-dhcp4.conf")

def check_or_install_kea():
    if is_kea_installed():
        return

    print("📦 Kea DHCP not found. Do you want to install it? [y/N]")
    choice = input().lower()
    if choice == "y":
        try:
            subprocess.run(["apt", "install", "-y", "software-properties-common"], check=True)
            subprocess.run(["add-apt-repository", "ppa:isc/kea"], check=True)
            subprocess.run(["apt", "update"], check=True)
            subprocess.run(["apt", "install", "-y", "kea-dhcp4-server", "kea-ctrl-agent"], check=True)
        except subprocess.CalledProcessError as e:
            print("❌ Failed to install Kea packages:", e)


# keaTUI-Update (new script)
#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/bcsanford/KeaTUI"
INSTALL_DIR="/opt/KeaTUI"
BIN_DIR="/usr/local/bin"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "📦 Installing KeaTUI from scratch..."
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "🔄 Updating KeaTUI..."
    git -C "$INSTALL_DIR" pull
fi

chmod +x "$INSTALL_DIR"/*.py

ln -sf "$INSTALL_DIR/main.py" "$BIN_DIR/KeaTUI"
ln -sf "$INSTALL_DIR/main.py" "$BIN_DIR/KeaTUI-Local"
ln -sf "$INSTALL_DIR/main.py" "$BIN_DIR/KeaTUI-Remote"

echo "✅ KeaTUI installed/updated successfully. Launch using:"
echo "  KeaTUI          # Select local/remote mode"
echo "  KeaTUI-Local    # Force local mode"
echo "  KeaTUI-Remote   # Prompt for remote API"
