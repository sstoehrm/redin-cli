#!/usr/bin/env bash
set -e

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
REPO="sstoehrm/redin-cli"

echo "Installing redin-cli to $INSTALL_DIR..."

if ! command -v bb &> /dev/null; then
    echo "Error: Babashka (bb) is required. Install from https://babashka.org/"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
curl -sL "https://raw.githubusercontent.com/$REPO/main/redin-cli" -o "$INSTALL_DIR/redin-cli"
chmod +x "$INSTALL_DIR/redin-cli"

echo "Installed redin-cli to $INSTALL_DIR/redin-cli"
echo ""

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Note: $INSTALL_DIR is not in your PATH."
    echo "Add this to your shell profile:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi
