#!/usr/bin/env bash

# ks - Enter knowledge system conversation mode
# Usage: ./ks [claude options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAT_DIR="$SCRIPT_DIR/chat"

cd "$CHAT_DIR" && claude "$@"