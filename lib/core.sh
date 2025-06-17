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

ks_create_conversation_dirs() {
    # Create conversation directory structure
    # Usage: ks_create_conversation_dirs "$CONVERSATION_NAME" ["$BASE_DIR"]
    local conversation_name="$1"
    local base_dir="${2:-}"
    
    if [[ -z "$conversation_name" ]]; then
        echo "Error: conversation name required" >&2
        return 1
    fi
    
    # Sanitize conversation name for filesystem
    local safe_name
    safe_name=$(ks_sanitize_string "$conversation_name")
    
    # Determine full path
    local full_path
    if [[ -n "$base_dir" ]]; then
        full_path="$base_dir/$safe_name"
    else
        full_path="$safe_name"
    fi
    
    # Create unified directory structure for ksd monitoring
    mkdir -p "$full_path/$KS_CONVERSATION_EVENTS_DIR"
    mkdir -p "$full_path/conversants"
    mkdir -p "$full_path/supervise"
    
    # Create symlinks back to ks project
    if [[ -n "${KS_ROOT:-}" ]]; then
        if [[ -d "$KS_ROOT/tools" ]]; then
            ln -sf "$KS_ROOT/tools" "$full_path/tools"
        fi
        if [[ -f "$KS_ROOT/.ks-env" ]]; then
            ln -sf "$KS_ROOT/.ks-env" "$full_path/.ks-env"
        fi
    fi
    
    echo "$full_path"
}

ks_validate_conversation_dir() {
    # Validate conversation directory exists and has required structure
    # Usage: ks_validate_conversation_dir "$CONVERSATION_NAME"
    local conversation_name="$1"
    
    if [[ ! -d "$conversation_name" ]]; then
        echo "Error: conversation directory '$conversation_name' does not exist" >&2
        return 1
    fi
    
    # Check for required subdirectories
    for subdir in conversants supervise; do
        if [[ ! -d "$conversation_name/$subdir" ]]; then
            echo "Error: missing required directory '$conversation_name/$subdir'" >&2
            return 1
        fi
    done
    
    # Check for unified knowledge structure
    if [[ ! -d "$conversation_name/$KS_CONVERSATION_EVENTS_DIR" ]]; then
        echo "Error: missing required directory '$conversation_name/$KS_CONVERSATION_EVENTS_DIR'" >&2
        return 1
    fi
    
    return 0
}

# Initialize directories on source
ks_ensure_dirs