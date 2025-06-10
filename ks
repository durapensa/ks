#!/usr/bin/env bash

# ks - Enter knowledge system conversation mode
# Usage: ./ks [claude options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAT_DIR="$SCRIPT_DIR/chat"

# Check for pending analyses from previous sessions
if [[ -f "$SCRIPT_DIR/.ks-env" ]]; then
    source "$SCRIPT_DIR/.ks-env"
    source "$KS_ROOT/lib/core.sh" 2>/dev/null || true
    source "$KS_ROOT/tools/lib/queue.sh" 2>/dev/null || true
    
    if command -v ks_queue_list_pending >/dev/null 2>&1; then
        pending=$(ks_queue_list_pending 2>/dev/null || echo "[]")
        if [[ "$pending" != "[]" ]]; then
            count=$(echo "$pending" | jq -r 'length' 2>/dev/null || echo "0")
            if [[ "$count" -gt 0 ]]; then
                echo "📋 $count analysis/analyses ready for review (tools/workflow/review-findings)"
                echo ""
            fi
        fi
    fi
fi

cd "$CHAT_DIR" && claude "$@"