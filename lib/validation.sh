#!/usr/bin/env bash
# Validation functions for category-based option parsing

# Source error handling for consistent error reporting
source "$KS_ROOT/lib/error.sh"

# Validate ANALYZE category options
# Usage: ks_validate_analyze_options "$DAYS" "$SINCE" "$TYPE" "$FORMAT" "$VERBOSE"
ks_validate_analyze_options() {
    local days="$1"
    local since="$2"
    local type="$3"
    local format="$4"
    local verbose="${5:-}"
    
    # Validate days if provided
    [[ -n "$days" ]] && ks_validate_days "$days"
    
    # Validate since date if provided
    [[ -n "$since" ]] && ks_validate_date "$since"
    
    # Validate format
    [[ -n "$format" ]] && ks_validate_format "$format"
    
    # Type is optional, no validation needed for now
    # Verbose is boolean, no validation needed
    
    return 0
}

# Validate CAPTURE_SEARCH category options  
ks_validate_capture_search_options() {
    local days="$1"
    local search="$2"
    local type="$3"
    local topic="$4"
    local limit="$5"
    local reverse="${6:-}"
    local count="${7:-}"
    
    [[ -n "$days" ]] && ks_validate_days "$days"
    [[ -n "$limit" ]] && ks_validate_positive_integer "$limit"
    
    return 0
}

# Validate INTROSPECT category options
ks_validate_introspect_options() {
    local batch_size="$1"
    local detailed="${2:-}"
    local interactive="${3:-}"
    local confidence_threshold="$4"
    local show_context="${5:-}"
    local auto_approve="${6:-}"
    
    [[ -n "$batch_size" ]] && ks_validate_positive_integer "$batch_size"
    [[ -n "$confidence_threshold" ]] && ks_validate_confidence "$confidence_threshold"
    
    return 0
}

# Validate PLUMBING category options (minimal validation for system tools)
ks_validate_plumbing_options() {
    # Most plumbing options are boolean flags, minimal validation needed
    return 0
}

# Helper validation functions (use existing ones from core.sh when available)

ks_validate_positive_integer() {
    local value="$1"
    [[ "$value" =~ ^[1-9][0-9]*$ ]] || {
        ks_error "'$value' must be a positive integer"
        return 1
    }
}

ks_validate_confidence() {
    local value="$1"
    # Check if it's a decimal between 0.0 and 1.0
    if ! [[ "$value" =~ ^0?\.[0-9]+$ ]] && ! [[ "$value" =~ ^1\.0*$ ]] && ! [[ "$value" == "0" ]] && ! [[ "$value" == "1" ]]; then
        ks_error "Confidence threshold '$value' must be between 0.0 and 1.0"
        return 1
    fi
}

# Re-export existing validation functions for use by categories
ks_validate_format() {
    local format="$1"
    case "$format" in
        text|json|markdown) return 0 ;;
        *) ks_error "Invalid format '$format'. Must be one of: text, json, markdown"; return 1 ;;
    esac
}

# Additional validation functions for common patterns

# Validate threshold values (0.0 to 1.0)
ks_validate_threshold() {
    local threshold="$1"
    if ! echo "$threshold" | rg -q '^[0-9]*\.?[0-9]+$'; then
        ks_error "Threshold must be a decimal number between 0.0 and 1.0"
        return 1
    fi
    local valid=$(echo "$threshold" | awk '$1 >= 0.0 && $1 <= 1.0 {print "valid"}')
    if [[ "$valid" != "valid" ]]; then
        ks_error "Threshold must be between 0.0 and 1.0"
        return 1
    fi
}

# Validate non-negative integers (including 0)
ks_validate_non_negative_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] || {
        ks_error "'$value' must be a non-negative integer"
        return 1
    }
}

# Validate file exists and is readable
ks_validate_readable_file() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]] || {
        ks_error "File '$file' does not exist or is not readable"
        return 1
    }
}

# Validate directory exists and is accessible
ks_validate_directory() {
    local dir="$1"
    [[ -d "$dir" ]] || {
        ks_error "Directory '$dir' does not exist"
        return 1
    }
}

# Note: ks_validate_days and ks_validate_date are available from core.sh/time.sh