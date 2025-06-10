#!/usr/bin/env bash
# Setup test framework for knowledge system

set -euo pipefail

echo "Setting up test framework..."

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is required to install bats-core on macOS"
        echo "Install Homebrew from: https://brew.sh"
        exit 1
    fi
    
    echo "Installing bats-core via Homebrew..."
    brew install bats-core
else
    # Linux installation
    echo "Installing bats-core from source..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone bats-core
    git clone https://github.com/bats-core/bats-core.git
    cd bats-core
    
    # Install to user's local bin
    ./install.sh "$HOME/.local"
    
    # Clean up
    cd ..
    rm -rf "$TEMP_DIR"
    
    echo "Bats installed to ~/.local/bin"
    echo "Make sure ~/.local/bin is in your PATH"
fi

# Verify installation
if command -v bats &> /dev/null; then
    echo "✓ bats-core successfully installed"
    bats --version
else
    echo "✗ bats-core installation failed"
    exit 1
fi

echo "Test framework setup complete!"