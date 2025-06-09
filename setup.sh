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

# Check dependencies and offer Homebrew installation on macOS
check_dependencies() {
    local missing_deps=()
    
    # Check for required dependencies
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    command -v claude >/dev/null 2>&1 || missing_deps+=("claude")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    
    # Check for optional but recommended dependencies
    command -v flock >/dev/null 2>&1 || missing_deps+=("util-linux")
    
    # On macOS, check for GNU coreutils for better compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v gdate >/dev/null 2>&1; then
            missing_deps+=("coreutils")
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        echo "Missing dependencies: ${missing_deps[*]}"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew >/dev/null 2>&1; then
                echo ""
                echo "Would you like to install missing dependencies via Homebrew?"
                echo "This will install: ${missing_deps[*]}"
                echo ""
                read -p "Install dependencies? (y/n): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "Installing dependencies..."
                    
                    # Install each missing dependency
                    for dep in "${missing_deps[@]}"; do
                        case "$dep" in
                            "claude")
                                echo "Note: Please install Claude CLI manually from https://claude.ai/cli"
                                ;;
                            "python3")
                                echo "Note: python3 should be available by default. If missing, install via Xcode Command Line Tools: xcode-select --install"
                                ;;
                            "util-linux")
                                brew install util-linux
                                ;;
                            *)
                                brew install "$dep"
                                ;;
                        esac
                    done
                    
                    echo "✓ Dependencies installed"
                else
                    echo "Skipping dependency installation"
                fi
            else
                echo ""
                echo "Consider installing Homebrew (https://brew.sh) for easier dependency management"
                echo "Then run: brew install ${missing_deps[*]// claude/}"
                echo "Notes:"
                echo "  - Install Claude CLI separately from https://claude.ai/cli"
                echo "  - python3 should be available by default via Xcode Command Line Tools"
            fi
        else
            echo "Please install missing dependencies using your system package manager"
            echo "Notes:"
            echo "  - Install Claude CLI separately from https://claude.ai/cli"
            echo "  - python3 should be available by default on most modern systems"
        fi
        echo ""
    fi
}

# Check and install dependencies
check_dependencies

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

# Check and update configuration
KS_CONFIGURED=0
GNU_TOOLS_CONFIGURED=0

if grep -q "KS_ROOT=" "$SHELL_CONFIG" 2>/dev/null; then
    KS_CONFIGURED=1
    echo "Knowledge System basic configuration found in $SHELL_CONFIG"
fi

if grep -q "coreutils/libexec/gnubin" "$SHELL_CONFIG" 2>/dev/null; then
    GNU_TOOLS_CONFIGURED=1
    echo "GNU tools PATH configuration found in $SHELL_CONFIG"
fi

# Add basic KS configuration if not present
if [ $KS_CONFIGURED -eq 0 ]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Knowledge System configuration" >> "$SHELL_CONFIG"
    echo "export KS_ROOT=\"$KS_ROOT\"" >> "$SHELL_CONFIG"
    echo "alias ks=\"\$KS_ROOT/ks\"" >> "$SHELL_CONFIG"
    echo "✓ Added basic Knowledge System configuration to $SHELL_CONFIG"
fi

# Add GNU tools PATH configuration on macOS if not present
if [[ "$OSTYPE" == "darwin"* ]] && [ $GNU_TOOLS_CONFIGURED -eq 0 ]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Prefer GNU tools on macOS for Knowledge System compatibility" >> "$SHELL_CONFIG"
    echo "if command -v brew >/dev/null 2>&1; then" >> "$SHELL_CONFIG"
    echo "    # Add GNU coreutils to PATH (for gdate, gstat, etc.)" >> "$SHELL_CONFIG"
    echo "    export PATH=\"\$(brew --prefix)/opt/coreutils/libexec/gnubin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "    # Add util-linux to PATH (for flock)" >> "$SHELL_CONFIG"
    echo "    export PATH=\"\$(brew --prefix)/opt/util-linux/bin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "fi" >> "$SHELL_CONFIG"
    echo "✓ Added GNU tools PATH configuration to $SHELL_CONFIG"
fi

if [ $KS_CONFIGURED -eq 1 ] && [ $GNU_TOOLS_CONFIGURED -eq 1 ]; then
    echo "Knowledge System fully configured in $SHELL_CONFIG"
fi

# If being sourced, also set up the current shell
if [ $SOURCED -eq 1 ]; then
    export KS_ROOT
    alias ks="$KS_ROOT/ks"
    
    # On macOS, prefer GNU tools for better compatibility
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
        # Add GNU coreutils to PATH (for gdate, gstat, etc.)
        export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
        # Add util-linux to PATH (for flock)
        export PATH="$(brew --prefix)/opt/util-linux/bin:$PATH"
    fi
    
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