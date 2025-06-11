#!/usr/bin/env bash

# Knowledge System Setup Script
# Usage: ./setup.sh        (updates shell config)
#        ./setup.sh -g     (also builds Go components)
#        source setup.sh  (updates shell config AND current session)

# Get the directory of this script
KS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect if script is being sourced or executed
SOURCED=0
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=1
fi

# On macOS, ensure GNU tools are in PATH for this script
if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
    # Add GNU getopt to PATH for option parsing
    export PATH="$(brew --prefix)/opt/gnu-getopt/bin:$PATH"
fi

# Parse command line arguments only when executed (not sourced)
SETUP_GO=0
if [[ $SOURCED -eq 0 ]] && [[ $# -gt 0 ]]; then
    # Use GNU getopt (will be available after first setup.sh run)
    TEMP=$(getopt -o g --long go -n 'setup.sh' -- "$@")
    if [ $? != 0 ]; then
        echo "Error: Invalid options"
        echo "Usage: ./setup.sh        # Basic setup"
        echo "       ./setup.sh -g     # Setup with Go components (or --go)"
        exit 1
    fi
    eval set -- "$TEMP"
    
    while true; do
        case "$1" in
            -g|--go)
                SETUP_GO=1
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Internal error!"
                exit 1
                ;;
        esac
    done
fi

echo "Setting up Knowledge System..."

# Source environment to create initial directories
source "$KS_ROOT/.ks-env"

# Check dependencies and offer Homebrew installation on macOS
check_dependencies() {
    local missing_deps=()
    
    # Check for required dependencies
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    command -v gum >/dev/null 2>&1 || missing_deps+=("gum")
    command -v claude >/dev/null 2>&1 || missing_deps+=("claude")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    
    # Additional bash tools for cleaner scripts
    command -v gnu-getopt >/dev/null 2>&1 || command -v getopt >/dev/null 2>&1 || missing_deps+=("gnu-getopt")
    command -v sd >/dev/null 2>&1 || missing_deps+=("sd")
    command -v rg >/dev/null 2>&1 || missing_deps+=("ripgrep")
    command -v pueue >/dev/null 2>&1 || missing_deps+=("pueue")
    command -v watchexec >/dev/null 2>&1 || missing_deps+=("watchexec")
    command -v sponge >/dev/null 2>&1 || missing_deps+=("moreutils")
    
    # Check for modern bash (5.x+)
    # First check if brew's bash is installed (even if not in PATH yet)
    local brew_bash_found=0
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
        local brew_prefix=$(brew --prefix)
        if [[ -x "$brew_prefix/bin/bash" ]]; then
            local brew_bash_version=$("$brew_prefix/bin/bash" --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            if [[ "$brew_bash_version" > "4.99" ]]; then
                brew_bash_found=1
            fi
        fi
    fi
    
    # If brew bash not found, check current bash in PATH
    if [[ $brew_bash_found -eq 0 ]]; then
        local bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [[ ! "$bash_version" > "4.99" ]]; then
            missing_deps+=("bash")
        fi
    fi
    
    # Check for optional but recommended dependencies
    command -v flock >/dev/null 2>&1 || missing_deps+=("util-linux")
    
    # On macOS, check for GNU coreutils for better compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v gdate >/dev/null 2>&1; then
            missing_deps+=("coreutils")
        fi
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
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
                    
                    # Check if bash was installed and provide guidance
                    for dep in "${missing_deps[@]}"; do
                        if [[ "$dep" == "bash" ]]; then
                            echo ""
                            echo "Note: Bash 5.x has been installed via Homebrew."
                            echo "To use it, reload your shell configuration or start a new terminal."
                        fi
                    done
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
            echo ""
            echo "For Ubuntu/Debian:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install jq python3 flock coreutils moreutils ripgrep"
            echo "  # For newer tools not in apt, use alternative methods:"
            echo "  # sd: cargo install sd"
            echo "  # pueue: cargo install pueue"
            echo "  # watchexec: cargo install watchexec-cli"
            echo "  # gum: see https://github.com/charmbracelet/gum#installation"
            echo ""
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
if [[ $KS_CONFIGURED -eq 0 ]]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Knowledge System configuration" >> "$SHELL_CONFIG"
    echo "export KS_ROOT=\"$KS_ROOT\"" >> "$SHELL_CONFIG"
    echo "alias ks=\"\$KS_ROOT/ks\"" >> "$SHELL_CONFIG"
    echo "alias ksd=\"\$KS_ROOT/ksd\"" >> "$SHELL_CONFIG"
    echo "✓ Added basic Knowledge System configuration to $SHELL_CONFIG"
fi

# Add GNU tools PATH configuration on macOS if not present
if [[ "$OSTYPE" == "darwin"* && $GNU_TOOLS_CONFIGURED -eq 0 ]]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Prefer GNU tools on macOS for Knowledge System compatibility" >> "$SHELL_CONFIG"
    echo "if command -v brew >/dev/null 2>&1; then" >> "$SHELL_CONFIG"
    echo "    # Add GNU coreutils to PATH (for gdate, gstat, etc.)" >> "$SHELL_CONFIG"
    echo "    export PATH=\"\$(brew --prefix)/opt/coreutils/libexec/gnubin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "    # Add util-linux to PATH (for flock)" >> "$SHELL_CONFIG"
    echo "    export PATH=\"\$(brew --prefix)/opt/util-linux/bin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "    # Add GNU getopt to PATH (for portable option parsing)" >> "$SHELL_CONFIG"
    echo "    export PATH=\"\$(brew --prefix)/opt/gnu-getopt/bin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "fi" >> "$SHELL_CONFIG"
    echo "✓ Added GNU tools PATH configuration to $SHELL_CONFIG"
fi

if [[ $KS_CONFIGURED -eq 1 && $GNU_TOOLS_CONFIGURED -eq 1 ]]; then
    echo "Knowledge System fully configured in $SHELL_CONFIG"
fi

# Go setup function
setup_go_components() {
    echo ""
    echo "Setting up Go components..."
    
    # Check if Go is installed
    if ! command -v go >/dev/null 2>&1; then
        echo "Go is not installed. Would you like to install it?"
        echo ""
        if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
            echo "Install via Homebrew? (y/n): "
            read -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Installing Go..."
                brew install go
            else
                echo "Please install Go manually from https://golang.org/dl/"
                return 1
            fi
        else
            echo "Please install Go from https://golang.org/dl/"
            echo "Then run: ./setup.sh -go"
            return 1
        fi
    fi
    
    # Build Go components
    if [[ -d "$KS_ROOT/go" ]]; then
        echo "Building Go components..."
        (cd "$KS_ROOT/go" && make build)
        if [[ $? -eq 0 ]]; then
            echo "✓ Go components built successfully"
        else
            echo "Error building Go components"
            return 1
        fi
    else
        echo "No Go components found in $KS_ROOT/go"
    fi
}

# Run Go setup if requested
if [[ $SETUP_GO -eq 1 ]]; then
    setup_go_components
fi

# If being sourced, also set up the current shell
if [[ $SOURCED -eq 1 ]]; then
    export KS_ROOT
    alias ks="$KS_ROOT/ks"
    alias ksd="$KS_ROOT/ksd"
    
    # On macOS, prefer GNU tools for better compatibility
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
        # Add GNU coreutils to PATH (for gdate, gstat, etc.)
        export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
        # Add util-linux to PATH (for flock)
        export PATH="$(brew --prefix)/opt/util-linux/bin:$PATH"
        # Add GNU getopt to PATH (for portable option parsing)
        export PATH="$(brew --prefix)/opt/gnu-getopt/bin:$PATH"
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
echo ""
echo "Optional Go components:"
echo "  Run './setup.sh -g' to install Go and build additional tools"