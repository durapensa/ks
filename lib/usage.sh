#!/usr/bin/env bash
# Standardized help text generation for consistent tool interfaces

# Standard spacing for option formatting (20 characters for option name)
readonly KS_OPTION_WIDTH=20

# Generate standardized usage text
# Usage: ks_generate_usage "description" "tool-name" "usage-pattern" "CATEGORY" arguments_array examples_array [custom_options_array]
ks_generate_usage() {
    local description="$1"
    local tool_name="$2" 
    local usage_pattern="$3"
    local category="$4"
    local -n arguments_ref=$5 2>/dev/null || declare -a arguments_ref=()
    local -n examples_ref=$6 2>/dev/null || declare -a examples_ref=()
    
    # Handle optional custom options parameter
    local custom_options_array=()
    if [[ $# -ge 7 && -n "${7:-}" ]]; then
        local -n custom_options_ref=$7
        custom_options_array=("${custom_options_ref[@]}")
    fi
    
    # Header
    echo "Description: $description"
    echo ""
    echo "Usage: $tool_name $usage_pattern"
    echo ""
    
    # Arguments section (if any)
    if [[ ${#arguments_ref[@]} -gt 0 ]]; then
        echo "Arguments:"
        for arg_line in "${arguments_ref[@]}"; do
            printf "  %s\n" "$arg_line"
        done
        echo ""
    fi
    
    # Options section
    echo "Options:"
    ks_format_category_options "$category"
    
    # Add custom options if provided
    if [[ ${#custom_options_array[@]} -gt 0 ]]; then
        for option_line in "${custom_options_array[@]}"; do
            printf "  %s\n" "$option_line"
        done
    fi
    echo ""
    
    # Examples section
    if [[ ${#examples_ref[@]} -gt 0 ]]; then
        echo "Examples:"
        for example in "${examples_ref[@]}"; do
            printf "  %s\n" "$example"
        done
    fi
}

# Format category-specific options with consistent spacing
ks_format_category_options() {
    local category="$1"
    
    # Universal help option
    printf "  %-${KS_OPTION_WIDTH}s %s\n" "--help" "Show this help"
    
    case "$category" in
        "ANALYZE")
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--days DAYS" "Analyze events from last N days (default: 7)"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--since SINCE" "Analyze events since ISO date"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--type TYPE" "Filter by event type"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--format FORMAT" "Output format (default: text)"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--verbose" "Show detailed output"
            ;;
        "CAPTURE_INPUT")
            # Minimal - just help (events tool)
            ;;
        "CAPTURE_SEARCH")
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--days DAYS" "Search last N days (default: 7)"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--since SINCE" "Search events since ISO date"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--type TYPE" "Filter by event type"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--topic TOPIC" "Filter by topic"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--limit LIMIT" "Limit results (default: 20)"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--reverse" "Show oldest first"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--count" "Show count only"
            ;;
        "PLUMBING")
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--verbose" "Show detailed output"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--dry-run" "Show what would be done"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--force" "Force operation"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--status" "Show status"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--active" "Show active only"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--completed" "Show completed only"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--failed" "Show failed only"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--cleanup" "Clean up stale entries"
            ;;
        "INTROSPECT")
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--list" "List pending items without reviewing"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--batch-size SIZE" "Review N items at once (default: 5)"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--detailed" "Show detailed analysis"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--interactive" "Enable interactive mode"
            printf "  %-${KS_OPTION_WIDTH}s %s\n" "--confidence-threshold" "Filter by confidence level (default: 0.5)"
            ;;
        "UTILS")
            # Custom per tool - no standard options
            ;;
        *)
            # Unknown category - just help option already printed
            ;;
    esac
}


# Helper function to format a custom option with consistent spacing
# Usage: ks_format_option "option-name" "description"
ks_format_option() {
    local option="$1"
    local description="$2"
    printf "%-${KS_OPTION_WIDTH}s %s" "$option" "$description"
}

