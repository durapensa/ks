#!/usr/bin/env bash

# Knowledge System Setup Script
# Usage: ./setup.sh        (updates shell config)
#        source setup.sh  (updates shell config AND current session)

# Get the directory of this script
KS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect if script is being sourced or executed
SOURCED=0
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=1
fi

echo "Setting up Knowledge System..."

# Source environment to create initial directories
source "$KS_ROOT/.ks-env"

# Detect user's actual shell (not the shell running this script)
USER_SHELL=$(basename "$SHELL")

case "$USER_SHELL" in
    zsh)
        SHELL_NAME="zsh"
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    bash)
        SHELL_NAME="bash"
        # Use .bash_profile on macOS, .bashrc on Linux
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    *)
        echo "Warning: Unknown shell '$USER_SHELL'. Please manually add the following to your shell config:"
        echo "  export KS_ROOT=\"$KS_ROOT\""
        echo "  alias ks=\"\$KS_ROOT/ks\""
        exit 0
        ;;
esac

# Check if already configured
if grep -q "KS_ROOT=" "$SHELL_CONFIG" 2>/dev/null; then
    echo "Knowledge System already configured in $SHELL_CONFIG"
    echo "To update, remove existing KS_ROOT lines and run setup again."
else
    # Add configuration to shell config
    echo "" >> "$SHELL_CONFIG"
    echo "# Knowledge System configuration" >> "$SHELL_CONFIG"
    echo "export KS_ROOT=\"$KS_ROOT\"" >> "$SHELL_CONFIG"
    echo "alias ks=\"\$KS_ROOT/ks\"" >> "$SHELL_CONFIG"
    
    echo "✓ Added configuration to $SHELL_CONFIG"
fi

# If being sourced, also set up the current shell
if [ $SOURCED -eq 1 ]; then
    export KS_ROOT
    alias ks="$KS_ROOT/ks"
    echo ""
    echo "✓ Knowledge System setup complete and active in current shell!"
else
    echo ""
    echo "Knowledge System setup complete!"
    echo ""
    echo "To activate in current shell, run ONE of:"
    echo "  source $SHELL_CONFIG"
    echo "  source $KS_ROOT/setup.sh"
fi

echo ""
echo "Usage:"
echo "  ks  - Start knowledge conversation with Claude"
echo ""
echo "Configuration:"
echo "  Set KS_MODEL to change Claude model (default: sonnet)"
echo "  Example: export KS_MODEL=opus"