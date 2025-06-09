#!/usr/bin/env bash

# Knowledge System Setup Script
# Usage: ./setup.sh

# Get the directory of this script
KS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Knowledge System..."

# Source environment to create initial directories
source "$KS_ROOT/.ks-env"

# Detect shell and config file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    # Use .bash_profile on macOS, .bashrc on Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
else
    echo "Warning: Unknown shell. Please manually add the following to your shell config:"
    echo "  export KS_ROOT=\"$KS_ROOT\""
    echo "  alias ks=\"\$KS_ROOT/ks\""
    exit 0
fi

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

echo ""
echo "Knowledge System setup complete!"
echo ""
echo "Usage:"
echo "  ks  - Start knowledge conversation with Claude"
echo ""
echo "Configuration:"
echo "  Set KS_MODEL to change Claude model (default: sonnet)"
echo "  Example: export KS_MODEL=opus"
echo ""
echo "To start using immediately, run:"
echo "  source $SHELL_CONFIG"