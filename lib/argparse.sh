#!/usr/bin/env bash
# argparse.sh - Runtime argument parsing library to eliminate repetitive code

# Ensure categories are loaded
[[ -z "${KS_CATEGORY_OPTIONS:-}" ]] && source "$KS_ROOT/lib/categories.sh"

# Build LONG_OPTS string from category and custom options
# Usage: ks_build_long_opts CATEGORY [custom_opts_array_name]
ks_build_long_opts() {
    local category="$1"
    local custom_ref="${2:-}"
    local long_opts="help"
    
    # Add category options
    if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
        local options="${KS_CATEGORY_OPTIONS[$category]}"
        while IFS='|' read -r long short desc default; do
            [[ -z "$long" ]] && continue
            if [[ "$default" == "BOOL" ]]; then
                long_opts="${long_opts},$long"
            else
                long_opts="${long_opts},$long:"
            fi
        done <<< "$options"
    fi
    
    # Add custom options if provided
    if [[ -n "$custom_ref" ]]; then
        local -n custom_opts=$custom_ref
        for opt in "${custom_opts[@]}"; do
            # Parse "name:TYPE" format
            local opt_name="${opt%%:*}"
            local opt_type="${opt#*:}"
            if [[ "$opt_type" == "BOOL" ]] || [[ "$opt" == "$opt_name" ]]; then
                long_opts="${long_opts},$opt_name"
            else
                long_opts="${long_opts},$opt_name:"
            fi
        done
    fi
    
    echo "$long_opts"
}

# Parse arguments using category definitions and custom options
# Usage: ks_parse_args CATEGORY custom_opts_ref args_out_ref -- "$@"
# Returns: Sets REMAINING_ARGS global array with unparsed positional args
ks_parse_args() {
    local category="$1"
    local -n custom_opts=$2
    local -n args_out=$3
    shift 3
    
    # Skip -- separator if present
    [[ "$1" == "--" ]] && shift
    
    # Build long options string
    local long_opts=$(ks_build_long_opts "$category" custom_opts)
    
    # Parse with getopt
    local opts
    opts=$($KS_GETOPT -o h -l "$long_opts" -- "$@") || ks_exit_usage "Invalid options provided"
    eval set -- "$opts"
    
    # Initialize args_out with defaults from category
    if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
        local options="${KS_CATEGORY_OPTIONS[$category]}"
        while IFS='|' read -r long short desc default; do
            [[ -z "$long" ]] && continue
            local var_name="${long//-/_}"
            if [[ "$default" != "BOOL" ]]; then
                args_out[$var_name]="${default:-}"
            else
                args_out[$var_name]=""
            fi
        done <<< "$options"
    fi
    
    # Process parsed options
    while true; do
        case "$1" in
            --help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            --*)
                local opt_name="${1#--}"
                local var_name="${opt_name//-/_}"
                
                # Check if this is a boolean option
                local is_bool=false
                
                # Check in category options
                if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
                    local options="${KS_CATEGORY_OPTIONS[$category]}"
                    while IFS='|' read -r long short desc default; do
                        if [[ "$long" == "$opt_name" ]] && [[ "$default" == "BOOL" ]]; then
                            is_bool=true
                            break
                        fi
                    done <<< "$options"
                fi
                
                # Check in custom options
                if [[ "$is_bool" == "false" ]]; then
                    for opt in "${custom_opts[@]}"; do
                        if [[ "$opt" == "$opt_name" ]] || [[ "$opt" == "$opt_name:BOOL" ]]; then
                            is_bool=true
                            break
                        fi
                    done
                fi
                
                if [[ "$is_bool" == "true" ]]; then
                    args_out[$var_name]="true"
                    shift
                else
                    args_out[$var_name]="$2"
                    shift 2
                fi
                ;;
            *)
                ks_exit_error "Internal argument parsing error"
                ;;
        esac
    done
    
    # Set global array with remaining args
    REMAINING_ARGS=("$@")
}

# Simplified argument parsing for standard category tools
# Usage: ks_parse_category_args CATEGORY -- "$@"
# Sets individual variables instead of using associative array
ks_parse_category_args() {
    local category="$1"
    shift
    [[ "$1" == "--" ]] && shift
    
    # Build long options from category
    local long_opts="help"
    if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
        local options="${KS_CATEGORY_OPTIONS[$category]}"
        while IFS='|' read -r long short desc default; do
            [[ -z "$long" ]] && continue
            if [[ "$default" == "BOOL" ]]; then
                long_opts="${long_opts},$long"
            else
                long_opts="${long_opts},$long:"
            fi
        done <<< "$options"
    fi
    
    # Parse with getopt
    local opts
    opts=$($KS_GETOPT -o h -l "$long_opts" -- "$@") || ks_exit_usage "Invalid options provided"
    eval set -- "$opts"
    
    # Process options and set variables directly
    while true; do
        case "$1" in
            --help) usage; exit 0 ;;
            --days) DAYS="$2"; shift 2 ;;
            --since) SINCE="$2"; shift 2 ;;
            --type) TYPE="$2"; shift 2 ;;
            --topic) TOPIC="$2"; shift 2 ;;
            --format) FORMAT="$2"; shift 2 ;;
            --verbose) VERBOSE=true; shift ;;
            --limit) LIMIT="$2"; shift 2 ;;
            --reverse) REVERSE=true; shift ;;
            --count) COUNT=true; shift ;;
            --search) SEARCH="$2"; shift 2 ;;
            --list) LIST=true; shift ;;
            --batch-size) BATCH_SIZE="$2"; shift 2 ;;
            --detailed) DETAILED=true; shift ;;
            --interactive) INTERACTIVE=true; shift ;;
            --confidence-threshold) CONFIDENCE_THRESHOLD="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --force) FORCE=true; shift ;;
            --status) STATUS=true; shift ;;
            --active) ACTIVE=true; shift ;;
            --completed) COMPLETED=true; shift ;;
            --failed) FAILED=true; shift ;;
            --cleanup) CLEANUP=true; shift ;;
            --template) TEMPLATE="$2"; shift 2 ;;
            --output) OUTPUT="$2"; shift 2 ;;
            --) shift; break ;;
            *) ks_exit_error "Internal argument parsing error" ;;
        esac
    done
    
    # Apply defaults from category
    if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
        local options="${KS_CATEGORY_OPTIONS[$category]}"
        while IFS='|' read -r long short desc default; do
            [[ -z "$long" ]] && continue
            local var_name="${long//-/_}"
            var_name="${var_name^^}"
            
            # Initialize all variables, even if empty
            if [[ "$default" == "BOOL" ]]; then
                # Boolean variables default to empty (false)
                declare -g "$var_name=${!var_name:-}"
            else
                # Set default value or empty string
                declare -g "$var_name=${!var_name:-$default}"
            fi
        done <<< "$options"
    fi
    
    # Set remaining args
    REMAINING_ARGS=("$@")
}

# Parse custom options along with category options
# Usage: ks_parse_custom_args CATEGORY custom_long_opts -- "$@"
# Example: ks_parse_custom_args "PLUMBING" "max-size:,max-age:,max-events:" -- "$@"
ks_parse_custom_args() {
    local category="$1"
    local custom_long_opts="$2"
    shift 2
    [[ "$1" == "--" ]] && shift
    
    # Build combined long options
    local long_opts="help"
    
    # Add category options
    if [[ -n "${KS_CATEGORY_OPTIONS[$category]:-}" ]]; then
        local options="${KS_CATEGORY_OPTIONS[$category]}"
        while IFS='|' read -r long short desc default; do
            [[ -z "$long" ]] && continue
            if [[ "$default" == "BOOL" ]]; then
                long_opts="${long_opts},$long"
            else
                long_opts="${long_opts},$long:"
            fi
        done <<< "$options"
    fi
    
    # Add custom options
    [[ -n "$custom_long_opts" ]] && long_opts="${long_opts},$custom_long_opts"
    
    # Parse with getopt
    local opts
    opts=$($KS_GETOPT -o h -l "$long_opts" -- "$@") || ks_exit_usage "Invalid options provided"
    eval set -- "$opts"
    
    # Return parsed options for caller to process
    echo "$opts"
}

# Validate and handle positional arguments
# Usage: ks_handle_positional required_names optional_names
# Example: ks_handle_positional "TYPE TOPIC" "CONTENT"
ks_handle_positional() {
    local required="$1"
    local optional="${2:-}"
    local -a required_array=($required)
    local -a optional_array=($optional)
    
    # Check required arguments
    if [[ ${#REMAINING_ARGS[@]} -lt ${#required_array[@]} ]]; then
        ks_exit_usage "Required arguments missing: $required"
    fi
    
    # Assign positional arguments to variables
    local index=0
    
    # Required arguments
    for var_name in "${required_array[@]}"; do
        if [[ $index -lt ${#REMAINING_ARGS[@]} ]]; then
            declare -g "$var_name=${REMAINING_ARGS[$index]}"
            ((index++))
        fi
    done
    
    # Optional arguments
    for var_name in "${optional_array[@]}"; do
        if [[ $index -lt ${#REMAINING_ARGS[@]} ]]; then
            declare -g "$var_name=${REMAINING_ARGS[$index]}"
            ((index++))
        else
            declare -g "$var_name="
        fi
    done
}

# Read content from argument or stdin
# Usage: CONTENT=$(ks_read_stdin_or_arg "$CONTENT_ARG" "${REMAINING_ARGS[0]:-}")
ks_read_stdin_or_arg() {
    local from_option="$1"
    local from_positional="${2:-}"
    
    # Priority: --option value > positional arg > stdin
    if [[ -n "$from_option" ]]; then
        echo "$from_option"
    elif [[ -n "$from_positional" ]]; then
        echo "$from_positional"
    elif [[ ! -t 0 ]]; then
        cat
    else
        echo ""
    fi
}

# Helper to check if running in silent mode
# Usage: if ks_is_silent "$VERBOSE"; then ...
ks_is_silent() {
    local verbose="${1:-}"
    [[ "$verbose" != "true" ]]
}

# Helper to get mode string for sub-commands
# Usage: MODE=$(ks_get_mode "$VERBOSE")
ks_get_mode() {
    local verbose="${1:-}"
    if [[ "$verbose" == "true" ]]; then
        echo "verbose"
    else
        echo "silent"
    fi
}

# Helper to determine action from boolean flags
# Usage: ACTION=$(ks_determine_action default_action flag1:action1 flag2:action2 ...)
# Example: ACTION=$(ks_determine_action "status" "$ACTIVE:active" "$COMPLETED:completed")
ks_determine_action() {
    local default_action="$1"
    shift
    
    for mapping in "$@"; do
        local flag="${mapping%%:*}"
        local action="${mapping#*:}"
        if [[ "$flag" == "true" ]]; then
            echo "$action"
            return
        fi
    done
    
    echo "$default_action"
}