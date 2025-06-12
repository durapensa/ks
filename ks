#!/usr/bin/env bash
# ks - Knowledge system CLI wrapper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/.ks-env" ]] && source "$SCRIPT_DIR/.ks-env"
source "$KS_ROOT/lib/argparse.sh"

# Define usage
ks_define_usage "Knowledge system CLI wrapper with dynamic subcommands"

# Tool discovery (must be defined before usage function)
declare -A TOOL_MAP
discover_tools() {
    while IFS= read -r tool; do
        local dir_name="${tool%/*}"
        local basename="${tool##*/}"
        
        if [[ "$dir_name" == "./capture" ]]; then
            TOOL_MAP["$basename"]="$KS_ROOT/tools/${tool#./}"
        else
            TOOL_MAP["${dir_name#./}-${basename}"]="$KS_ROOT/tools/${tool#./}"
        fi
    done < <(cd "$KS_ROOT/tools" && $KS_FIND . -type f -executable ! -name "*.*")
}

# Custom usage function that shows available subcommands
usage() {
    echo "Usage: ${0##*/} [options] [subcommand] [args...]"
    echo ""
    echo "When no subcommand is provided, enters interactive capture mode."
    echo ""
    echo "Available subcommands:"
    
    # Use existing TOOL_MAP if already populated
    if [[ ${#TOOL_MAP[@]} -eq 0 ]]; then
        discover_tools
    fi
    
    # Group by category for better display
    local -A categories
    for subcommand in "${!TOOL_MAP[@]}"; do
        local tool="${TOOL_MAP[$subcommand]}"
        local rel_path="${tool#$KS_ROOT/tools/}"
        local category="${rel_path%/*}"
        categories["$category"]+="$subcommand "
    done
    
    for category in $(printf '%s\n' "${!categories[@]}" | sort); do
        echo "  $category:"
        for subcommand in ${categories[$category]}; do
            printf "    %-20s → %s\n" "$subcommand" "${TOOL_MAP[$subcommand]#$KS_ROOT/}"
        done
    done
    
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "      --allhelp       Show help for all available tools"
    echo ""
    echo "Examples:"
    echo "  ${0##*/}                    # Interactive mode with Claude"
    echo "  ${0##*/} events thought \"topic\" \"content\""
    echo "  ${0##*/} query --days 7 \"search term\""
    echo "  ${0##*/} analyze-extract-themes --format json"
}

# Handle subcommands before processing ks options
# This prevents subcommand --help from being intercepted by ks
if [[ $# -gt 0 && "$1" != --* ]]; then
    # This is a subcommand, handle it directly
    discover_tools
    
    subcommand="$1"
    shift
    
    if [[ -n "${TOOL_MAP[$subcommand]:-}" ]]; then
        exec "${TOOL_MAP[$subcommand]}" "$@"
    else
        echo "Unknown subcommand: $subcommand"
        echo "Run '${0##*/} --help' to see available subcommands"
        exit 1
    fi
fi

# Initialize and define options
ks_init_options
ks_option "allhelp" "" "Show help for all available tools" "" "" "flag"

# Process options (only if no subcommand was provided)
ks_process_options "$@"

# Helper function for parallel processing
process_tool_help() {
    local subcommand="$1"
    local tool_path="${TOOL_MAP[$subcommand]#$KS_ROOT/}"
    local tool_file="${TOOL_MAP[$subcommand]}"
    
    echo "$tool_path --help"
    "$tool_file" --help 2>/dev/null || echo "No help available"
    echo
    echo "$tool_path --examples"
    "$tool_file" --examples 2>/dev/null || echo "No examples available"
    echo
}

# Export function and TOOL_MAP for parallel
export -f process_tool_help
export TOOL_MAP
export KS_ROOT

# Show all help using GNU parallel for speed with order preservation
show_all_help() {
    echo "ks --help"
    usage
    echo
    
    # Use GNU parallel with --keep-order to preserve tool ordering
    printf '%s\n' "${!TOOL_MAP[@]}" | sort | parallel --keep-order process_tool_help
}

# Check pending analyses
check_pending() {
    if [[ -f "$KS_ROOT/lib/core.sh" && -f "$KS_ROOT/tools/lib/queue.sh" ]]; then
        source "$KS_ROOT/lib/core.sh" 2>/dev/null || true
        source "$KS_ROOT/tools/lib/queue.sh" 2>/dev/null || true
        
        if command -v ks_queue_list_pending >/dev/null 2>&1; then
            local pending=$(ks_queue_list_pending 2>/dev/null || echo "[]")
            if [[ "$pending" != "[]" ]]; then
                local count=$(echo "$pending" | jq -r 'length' 2>/dev/null || echo "0")
                if [[ "$count" -gt 0 ]]; then
                    echo "📋 $count analysis/analyses ready for review"
                    echo
                fi
            fi
        fi
    fi
}

# Handle --allhelp
if [[ "${ALLHELP:-false}" == "true" ]]; then
    discover_tools
    show_all_help
    exit 0
fi

# No args = interactive mode
if [[ ${#REMAINING_ARGS[@]} -eq 0 ]]; then
    check_pending
    
    # Create Claude session with tools context
    discover_tools
    echo "Initializing Claude with knowledge system tools context..."
    
    # Create .claude directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/chat/.claude"
    
    # Generate dynamic tool reference file
    {
        echo "# Knowledge System Tool Reference"
        echo
        echo "Complete reference for all available tools in this knowledge system."
        echo "Each tool can be invoked directly using the paths shown below."
        echo
        show_all_help
    } > "$SCRIPT_DIR/chat/.claude/ks-instructions.md"
    
    # Start Claude with both project context and tools reference
    cd "$SCRIPT_DIR/chat"
    {
        echo "SYSTEM CONTEXT:"
        echo "@CLAUDE.md"
        echo "@.claude/ks-instructions.md"
        echo "---"
        echo "Ready for knowledge system interaction."
    } | claude
    exit 0
fi

# Discover tools and handle subcommand
discover_tools

subcommand="${REMAINING_ARGS[0]}"
tool_args=("${REMAINING_ARGS[@]:1}")

if [[ -n "${TOOL_MAP[$subcommand]:-}" ]]; then
    exec "${TOOL_MAP[$subcommand]}" "${tool_args[@]}"
else
    echo "Unknown subcommand: $subcommand"
    echo "Available: $(printf '%s ' "${!TOOL_MAP[@]}" | sort)"
    exit 1
fi
