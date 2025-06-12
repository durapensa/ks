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

# Custom usage function that shows available subcommands
usage() {
    discover_tools
    
    echo "Usage: ${0##*/} [OPTION]... [SUBCOMMAND] [ARGS]..."
    echo "Knowledge system CLI for interactive capture and analysis."
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
                
                # Simple descriptions based on tool names
                case "$subcommand" in
                    events) printf "    %-20s %s\n" "$subcommand" "append events to knowledge stream" ;;
                    query) printf "    %-20s %s\n" "$subcommand" "search existing knowledge" ;;
                    extract-themes) printf "    %-20s %s\n" "$subcommand" "identify key themes from events" ;;
                    find-connections) printf "    %-20s %s\n" "$subcommand" "discover relationships between concepts" ;;
                    curate-duplicate-knowledge) printf "    %-20s %s\n" "$subcommand" "detect redundant insights" ;;
                    identify-recurring-thought-patterns) printf "    %-20s %s\n" "$subcommand" "analyze thinking patterns" ;;
                    review-findings) printf "    %-20s %s\n" "$subcommand" "review and approve analysis results" ;;
                    check-event-triggers) printf "    %-20s %s\n" "$subcommand" "monitor background analysis triggers" ;;
                    monitor-background-processes) printf "    %-20s %s\n" "$subcommand" "track system processes" ;;
                    rotate-logs) printf "    %-20s %s\n" "$subcommand" "manage log file rotation" ;;
                    validate-jsonl) printf "    %-20s %s\n" "$subcommand" "verify JSONL file format" ;;
                    *) printf "    %-20s %s\n" "$subcommand" "tool description" ;;
                esac
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

# Export function for parallel
export -f process_tool_help
export KS_ROOT

# Show all help using GNU parallel for speed with order preservation
show_all_help() {
    echo "ks --help"
    usage
    echo
    
    # Use GNU parallel with --keep-order to preserve tool ordering
    printf '%s\n' "${TOOL_MAP[@]}" | sort | parallel --keep-order process_tool_help
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
