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


# Helper validation functions

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


# Note: ks_validate_days and ks_validate_date are available from core.sh/time.sh