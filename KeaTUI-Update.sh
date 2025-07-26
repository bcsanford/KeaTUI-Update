#!/usr/bin/env bash
# keaTUI-Update - Script to update KeaTUI from GitHub

set -e

REPO_URL="https://github.com/bcsanford/kea_tui"
BRANCH="main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="KeaTUI"
TMP_DIR=$(mktemp -d)
GITHUB_API="https://api.github.com/repos/bcsanford/kea_tui/releases/latest"

echo "🔄 Checking for updates from $REPO_URL..."

# Fetch latest release info
echo "🌐 Fetching latest release info..."
LATEST_URL=$(curl -s "$GITHUB_API" | grep "browser_download_url" | grep -Ei "\.py|\.tar\.gz" | head -n 1 | cut -d '"' -f 4)

if [[ -z "$LATEST_URL" ]]; then
    echo "❌ Failed to fetch latest release URL."
    exit 1
fi

echo "📥 Downloading from $LATEST_URL..."
curl -L "$LATEST_URL" -o "$TMP_DIR/KeaTUI_download"

# Determine if it's a Python file or tar.gz
if [[ "$LATEST_URL" == *.py ]]; then
    echo "📄 Updating script..."
    install -m 755 "$TMP_DIR/KeaTUI_download" "$INSTALL_DIR/$SCRIPT_NAME"
elif [[ "$LATEST_URL" == *.tar.gz ]]; then
    echo "📦 Extracting archive..."
    tar -xzf "$TMP_DIR/KeaTUI_download" -C "$TMP_DIR"
    if [[ -f "$TMP_DIR"/KeaTUI ]]; then
        install -m 755 "$TMP_DIR/KeaTUI" "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo "❌ KeaTUI script not found in archive."
        exit 1
    fi
else
    echo "❌ Unknown release format."
    exit 1
fi

echo "✅ KeaTUI successfully updated to the latest version."
