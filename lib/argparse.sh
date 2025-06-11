#!/usr/bin/env bash
# Library for standardized command-line argument parsing using GNU getopt

# Global arrays for option definitions
declare -gA KS_OPTIONS_SHORT
declare -gA KS_OPTIONS_LONG  
declare -gA KS_OPTIONS_DESC
declare -gA KS_OPTIONS_DEFAULT
declare -gA KS_OPTIONS_HANDLER

# Parse command line options using GNU getopt
# Usage: ks_parse_options "script-name" "short-opts" "long-opts" "$@"
# Returns: Parsed options ready for eval
ks_parse_options() {
    local script_name="$1"
    local short_opts="$2" 
    local long_opts="$3"
    shift 3
    
    # Always include -h for help
    short_opts="h${short_opts}"
    long_opts="help${long_opts:+,}${long_opts}"
    
    # Parse options
    local parsed
    if ! parsed=$(getopt -o "$short_opts" --long "$long_opts" -n "$script_name" -- "$@"); then
        return 1
    fi
    
    echo "$parsed"
}

# Handle standard help option
# Usage: ks_handle_help "$1" && shift || true
ks_handle_help() {
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
    esac
}

# Handle --days option with validation
# Usage: ks_handle_days "$2" && shift 2
ks_handle_days() {
    local days="$1"
    DAYS="$days"
    # Validate using existing function from core.sh
    ks_validate_days "$DAYS" || exit 1
}

# Handle --since option with validation
# Usage: ks_handle_since "$2" && shift 2
ks_handle_since() {
    local since="$1"
    SINCE="$since"
    # Validate using function from time.sh
    ks_validate_date "$SINCE" || { ks_error "Invalid date format: $SINCE"; exit 1; }
}

# Handle --format option with validation
# Usage: ks_handle_format "$2" && shift 2
ks_handle_format() {
    local format="$1"
    case "$format" in
        text|json|markdown)
            FORMAT="$format"
            ;;
        *)
            ks_error "Invalid format: $format. Must be one of: text, json, markdown"
            exit 1
            ;;
    esac
}

# Standard error handler for unknown options
# Usage: ks_unknown_option "$1"
ks_unknown_option() {
    ks_error "Unknown option: $1"
    echo "Use --help for usage information" >&2
    exit 1
}

# Consistent error output
# Usage: ks_error "error message"
ks_error() {
    echo "Error: $1" >&2
}

# Build jq filter from common options
# Usage: filter=$(ks_build_filter "$TYPE_FILTER" "$TOPIC_FILTER")
ks_build_filter() {
    local type_filter="$1"
    local topic_filter="$2"
    local filter="."
    
    if [[ -n "$type_filter" ]]; then
        filter="$filter | select(.type == \"$type_filter\")"
    fi
    
    if [[ -n "$topic_filter" ]]; then
        filter="$filter | select(.metadata.topic == \"$topic_filter\")"
    fi
    
    echo "$filter"
}

# Extract event content for analysis with time filtering
# Usage: content=$(ks_extract_events "$DAYS" "$SINCE" "$FILTER")
ks_extract_events() {
    local days="${1:-}"
    local since="${2:-}"
    local filter="${3:-.}"
    local content=""
    
    # Get filter date
    local filter_date=$(ks_get_filter_date "$days" "$since")
    
    # Collect only relevant files
    ks_collect_files_since "$filter_date"
    
    # Build jq filter with date
    local date_filter="select(.ts >= \"$filter_date\")"
    local full_filter="$date_filter | $filter"
    
    # Extract content from each file
    for file in "${FILES_TO_PROCESS[@]}"; do
        if [[ -f "$file" && -s "$file" ]]; then
            local file_content
            file_content=$(jq -r "$full_filter | \"\(.ts // \"unknown\"): \(.type // \"unknown\") - \(.thought // .observation // .question // \"empty\")\"" "$file" 2>/dev/null || true)
            [[ -n "$file_content" ]] && content="${content}${file_content}"$'\n'
        fi
    done
    
    echo "$content"
}

# Define an option for argument parsing
# Usage: ks_option "days" "d" "Analyze events from last N days" "7" "ks_handle_days"
ks_option() {
    local name="$1"
    local short="${2:-}"
    local desc="${3:-}"
    local default="${4:-}"
    local handler="${5:-}"
    
    KS_OPTIONS_LONG["$name"]="$name"
    [[ -n "$short" ]] && KS_OPTIONS_SHORT["$name"]="$short"
    KS_OPTIONS_DESC["$name"]="$desc"
    [[ -n "$default" ]] && KS_OPTIONS_DEFAULT["$name"]="$default"
    [[ -n "$handler" ]] && KS_OPTIONS_HANDLER["$name"]="$handler"
}

# Generate usage from defined options
# Usage: ks_usage "script-name" "description"
ks_usage() {
    local script_name="$1"
    local description="$2"
    
    echo "Usage: $script_name [options]"
    echo ""
    echo "Options:"
    
    # Always show help first
    echo "  -h, --help      Show this help message"
    
    # Show other options
    for name in "${!KS_OPTIONS_LONG[@]}"; do
        local short_opt=""
        [[ -n "${KS_OPTIONS_SHORT[$name]}" ]] && short_opt="-${KS_OPTIONS_SHORT[$name]}, "
        local default=""
        [[ -n "${KS_OPTIONS_DEFAULT[$name]}" ]] && default=" (default: ${KS_OPTIONS_DEFAULT[$name]})"
        
        # Check if option takes an argument
        local arg_text=""
        if [[ "${KS_OPTIONS_HANDLER[$name]}" != "" ]]; then
            arg_text=" ${name^^}"
        fi
        
        printf "  %-15s %s%s\n" "${short_opt}--${name}${arg_text}" "${KS_OPTIONS_DESC[$name]}" "$default"
    done
    
    echo ""
    echo "$description"
}

# Process all options using definitions
# Usage: ks_process_options "$@"
ks_process_options() {
    local script_name="${0##*/}"
    
    # Build getopt strings from definitions
    local short_opts=""
    local long_opts=""
    
    for name in "${!KS_OPTIONS_LONG[@]}"; do
        if [[ -n "${KS_OPTIONS_SHORT[$name]}" ]]; then
            short_opts="${short_opts}${KS_OPTIONS_SHORT[$name]}:"
        fi
        long_opts="${long_opts}${name}:,"
    done
    
    # Parse and process options
    local parsed
    parsed=$(ks_parse_options "$script_name" "$short_opts" "$long_opts" "$@") || {
        ks_usage "$script_name" ""
        exit 1
    } >&2
    
    eval set -- "$parsed"
    
    while true; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                # Find matching option
                local handled=false
                for name in "${!KS_OPTIONS_LONG[@]}"; do
                    local short_match=false
                    local long_match=false
                    
                    [[ -n "${KS_OPTIONS_SHORT[$name]}" && "$1" == "-${KS_OPTIONS_SHORT[$name]}" ]] && short_match=true
                    [[ "$1" == "--${name}" ]] && long_match=true
                    
                    if [[ "$short_match" == true || "$long_match" == true ]]; then
                        if [[ -n "${KS_OPTIONS_HANDLER[$name]}" ]]; then
                            ${KS_OPTIONS_HANDLER[$name]} "$2"
                        else
                            # Direct variable assignment
                            declare -g "${name^^}_FILTER=$2"
                        fi
                        shift 2
                        handled=true
                        break
                    fi
                done
                
                [[ "$handled" == false ]] && ks_unknown_option "$1"
                ;;
        esac
    done
}