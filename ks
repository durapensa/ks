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
declare -A TOOL_CATEGORIES

discover_tools() {
    local find_cmd="${KS_FIND:-gfind}"
    
    while IFS= read -r tool; do
        local basename="${tool##*/}"
        local category="${tool%/*}"
        category="${category#./}"  # Remove leading ./
        
        TOOL_MAP["$basename"]="$KS_ROOT/tools/${tool#./}"
        TOOL_CATEGORIES["$basename"]="$category"
    done < <(cd "$KS_ROOT/tools" && $find_cmd . -type f -executable ! -name "*.*" | sort)
}

# Generalized parallel processing function
parallel_process_tools() {
    local operation_func="$1"
    export -f "$operation_func"
    printf '%s\n' "${TOOL_MAP[@]}" | sort | parallel --keep-order "$operation_func"
}

# Extract tool description from --help output
extract_description() {
    local tool_file="$1"
    local basename="${tool_file##*/}"
    local desc=$("$tool_file" --help 2>/dev/null | grep "^Description: " | sed 's/^Description: //')
    echo "$basename:$desc"
}

# Export functions for parallel
export -f extract_description

# Custom usage function that shows available subcommands
usage() {
    discover_tools
    
    # Extract all tool descriptions upfront using parallel processing
    declare -A TOOL_DESCRIPTIONS
    while IFS=: read -r tool_name description; do
        TOOL_DESCRIPTIONS["$tool_name"]="$description"
    done < <(parallel_process_tools extract_description)
    
    echo "Description: Knowledge system CLI for interactive capture and analysis."
    echo ""
    echo "Usage: ${0##*/} [OPTION]... [SUBCOMMAND] [ARGS]..."
    echo ""
    echo "Available subcommands:"
    
    # Group by categories we know exist
    for category in capture analyze workflow plumbing utils; do
        local has_tools=false
        for subcommand in $(printf '%s\n' "${!TOOL_MAP[@]}" | sort); do
            if [[ "${TOOL_CATEGORIES[$subcommand]}" == "$category" ]]; then
                if [[ "$has_tools" == false ]]; then
                    echo "  ${category^^}:"
                    has_tools=true
                fi
                
                # Use extracted description or fallback
                local desc="${TOOL_DESCRIPTIONS[$subcommand]:-tool description}"
                printf "    %-20s %s\n" "$subcommand" "$desc"
            fi
        done
        [[ "$has_tools" == true ]] && echo ""
    done
    
    echo "Options:"
    echo "  -h, --help           show this help and exit"
    echo "      --allhelp        show help for all tools"
    echo ""
    echo "Examples:"
    echo "  ${0##*/}                   start interactive mode with Claude"
    echo "  ${0##*/} events thought \"learning\" \"new insight\""
    echo "  ${0##*/} query \"search term\""
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
    local tool_file="$1"
    local tool_path="${tool_file#$KS_ROOT/}"
    
    echo "$tool_path --help --examples"
    "$tool_file" --help --examples 2>/dev/null || echo "No help or examples available"
    echo
}

# Export functions for parallel
export -f process_tool_help
export KS_ROOT

# Show all help using GNU parallel for speed with order preservation
show_all_help() {
    echo "ks --help"
    usage
    echo
    
    # Use generalized parallel processing
    parallel_process_tools process_tool_help
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
