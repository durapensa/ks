#!/usr/bin/env bash
# Knowledge System Core Library
# Essential utilities used across all tools

ks_ensure_dirs() {
    # Ensure all required directories exist
    mkdir -p "$KS_EVENTS_DIR" "$KS_ARCHIVE_DIR" "$KS_DERIVED_DIR"
    mkdir -p "$KS_PROCESS_REGISTRY"/{active,completed,failed}
    mkdir -p "$KS_BACKGROUND_DIR"/findings
}

ks_timestamp() {
    # Generate UTC timestamp in ISO format
    $KS_DATE -u '+%Y-%m-%dT%H:%M:%SZ'
}

ks_sanitize_string() {
    # Basic sanitization for user input to prevent command injection
    # Usage: CLEAN_VAR=$(ks_sanitize_string "$USER_INPUT")
    local input="$1"
    
    # Remove or escape potentially dangerous characters
    # Allow alphanumeric, spaces, hyphens, underscores, periods, colons
    # Replace slashes and spaces with underscores for safe filenames
    echo "$input" | sd '[^a-zA-Z0-9 _.:-]' '' | sd '[/ ]' '_'
}

ks_validate_days() {
    # Validate --days parameter is a positive integer
    # Usage: ks_validate_days "$DAYS"
    local days="$1"
    
    if ! [[ "$days" =~ ^[0-9]+$ ]] || [[ "$days" -le 0 ]]; then
        echo "Error: --days must be a positive integer, got: '$days'" >&2
        return 1
    fi
    
    # Reasonable upper limit to prevent accidents
    if [[ "$days" -gt 3650 ]]; then
        echo "Warning: --days value '$days' is unusually large (>10 years)" >&2
    fi
    
    return 0
}

# Initialize directories on source
ks_ensure_dirs