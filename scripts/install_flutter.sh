#!/bin/bash
# Installs the Flutter SDK locally into <repo>/flutter (gitignored).
# Usage: scripts/install_flutter.sh [--force]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
FLUTTER_REPO="https://github.com/flutter/flutter.git"

if [ "${1:-}" = "--force" ] && [ -d "$FLUTTER_DIR" ]; then
    echo "Removing existing Flutter SDK at $FLUTTER_DIR"
    rm -rf "$FLUTTER_DIR"
fi

if [ -x "$FLUTTER_BIN" ]; then
    echo "Flutter SDK already installed at $FLUTTER_DIR"
else
    echo "Cloning Flutter stable into $FLUTTER_DIR"
    git clone --depth 1 --branch stable "$FLUTTER_REPO" "$FLUTTER_DIR"
fi

"$FLUTTER_BIN" --version
"$FLUTTER_BIN" config --no-analytics

if [ -d "$HOME/Android/Sdk" ]; then
    "$FLUTTER_BIN" config --android-sdk "$HOME/Android/Sdk"
fi

"$FLUTTER_BIN" doctor || true
