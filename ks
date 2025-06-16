#!/usr/bin/env bash
# ks - Knowledge system CLI wrapper (simplified)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/.ks-env" ]] && source "$SCRIPT_DIR/.ks-env"

declare -A TOOL_MAP TOOL_CATEGORIES

# === CORE FUNCTIONS ===

discover_tools() {
    [[ -v TOOL_MAP && ${#TOOL_MAP[@]} -gt 0 ]] && return
    local find_cmd="${KS_FIND:-gfind}"
    while IFS= read -r tool; do
        local basename="${tool##*/}"
        local category="${tool%/*}"
        category="${category#./}"
        TOOL_MAP["$basename"]="$KS_ROOT/tools/${tool#./}"
        TOOL_CATEGORIES["$basename"]="$category"
    done < <(cd "$KS_ROOT/tools" && $find_cmd . -type f -executable ! -name "*.*" | sort)
}

parallel_process_tools() {
    local operation_func="$1"
    export -f "$operation_func"
    printf '%s\n' "${TOOL_MAP[@]}" | sort | parallel --keep-order "$operation_func"
}

extract_description() {
    local tool_file="$1"
    local basename="${tool_file##*/}"
    local desc=$("$tool_file" --help 2>/dev/null | grep "^Description: " | sed 's/^Description: //')
    echo "$basename:$desc"
}

export -f extract_description
export KS_ROOT

# === ACTION FUNCTIONS ===

show_usage() {
    local skip_descriptions="${1:-false}"
    discover_tools
    
    echo "Description: Knowledge system CLI for interactive capture and analysis."
    echo ""
    echo "Usage: ${0##*/} [OPTION]... [SUBCOMMAND] [ARGS]..."
    echo ""
    echo "Available subcommands:"
    
    # Get descriptions if needed - simplified approach
    declare -A TOOL_DESCRIPTIONS
    if [[ "$skip_descriptions" != "true" ]]; then
        while IFS=: read -r tool_name description; do
            TOOL_DESCRIPTIONS["$tool_name"]="$description"
        done < <(parallel_process_tools extract_description)
    fi
    
    # Display by hardcoded categories (for now)  
    for category in capture analyze introspect plumbing utils; do
        local has_tools=false
        for subcommand in $(printf '%s\n' "${!TOOL_MAP[@]}" | sort); do
            if [[ "${TOOL_CATEGORIES[$subcommand]}" == "$category" ]]; then
                if [[ "$has_tools" == false ]]; then
                    echo "  ${category^^}:"
                    has_tools=true
                fi
                local desc="${TOOL_DESCRIPTIONS[$subcommand]:-tool description}"
                printf "    %-20s %s\n" "$subcommand" "$desc"
            fi
        done
        [[ "$has_tools" == true ]] && echo ""
    done
    
    echo "Options:"
    echo "  -h, --help           show this help and exit"
    echo "      --claudehelp     show help for ks and key capture tools"
    echo "      --allhelp        show help for all tools"
    echo ""
    echo "Examples:"
    echo "  ${0##*/}                   start interactive mode with Claude"
    echo "  ${0##*/} events thought \"learning\" \"new insight\""
    echo "  ${0##*/} query \"search term\""
}

show_all_help() {
    echo "ks --allhelp"
    show_usage true
    echo
    parallel_process_tools process_tool_help
}

show_claude_help() {
    echo "ks --claudehelp"
    echo ""
    show_usage
    echo ""
    echo "=== Key Capture Tools ==="
    echo ""
    for tool in events query; do
        if [[ -n "${TOOL_MAP[$tool]:-}" ]]; then
            echo "--- $tool ---"
            "${TOOL_MAP[$tool]}" --help
            echo ""
        fi
    done
}

process_tool_help() {
    local tool_file="$1"
    local tool_path="${tool_file#$KS_ROOT/}"
    echo "$tool_path --help --examples"
    "$tool_file" --help --examples 2>/dev/null || echo "No help or examples available"
    echo
}

export -f process_tool_help

check_pending() {
    [[ ! -f "$KS_ROOT/lib/core.sh" || ! -f "$KS_ROOT/tools/lib/queue.sh" ]] && return
    source "$KS_ROOT/lib/core.sh" 2>/dev/null || return
    source "$KS_ROOT/tools/lib/queue.sh" 2>/dev/null || return
    command -v ks_queue_list_pending >/dev/null 2>&1 || return
    local pending=$(ks_queue_list_pending 2>/dev/null || echo "[]")
    [[ "$pending" == "[]" ]] && return
    local count=$(echo "$pending" | jq -r 'length' 2>/dev/null || echo "0")
    [[ "$count" -gt 0 ]] && echo "📋 $count analysis/analyses ready for review" && echo
}

interactive_mode() {
    check_pending
    echo "Initializing Claude with knowledge system tools context..."
    mkdir -p "$SCRIPT_DIR/chat/.claude"
    
    {
        echo "# Knowledge System Tool Reference"
        echo ""
        echo "Core knowledge system CLI and key capture tools."
        echo "Each tool can be invoked directly using the paths shown below."
        echo ""
        show_claude_help
    } > "$SCRIPT_DIR/chat/.claude/ks-instructions.md"
    
    cd "$SCRIPT_DIR/chat"
    {
        echo "SYSTEM CONTEXT:"
        echo "@CLAUDE.md"
        echo "@.claude/ks-instructions.md"
        echo "---"
        echo "Ready for knowledge system interaction."
    } | claude
}

# === MAIN DISPATCHER ===

discover_tools

case "${1:-}" in
    --allhelp)
        show_all_help
        ;;
    --claudehelp)
        show_claude_help
        ;;
    --help|-h)
        show_usage
        ;;
    "")
        interactive_mode
        ;;
    *)
        # Handle subcommand
        subcommand="$1"
        shift
        if [[ -n "${TOOL_MAP[$subcommand]:-}" ]]; then
            exec "${TOOL_MAP[$subcommand]}" "$@"
        else
            echo "Unknown subcommand: $subcommand"
            echo "Available: $(printf '%s ' "${!TOOL_MAP[@]}" | sort)"
            exit 1
        fi
        ;;
esac