#!/usr/bin/env bash
# Time filtering utilities for Knowledge System

# Convert days to ISO date
# Usage: date=$(ks_days_to_date 7)
ks_days_to_date() {
    local days="$1"
    $KS_DATE -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ
}

# Validate ISO date format
# Usage: ks_validate_date "2024-01-01T00:00:00Z" || exit 1
ks_validate_date() {
    local date_str="$1"
    $KS_DATE -d "$date_str" >/dev/null 2>&1
}

# Get filter date from --days or --since parameters
# Usage: filter_date=$(ks_get_filter_date "$DAYS" "$SINCE")
ks_get_filter_date() {
    local days="${1:-}"
    local since="${2:-}"
    
    if [[ -n "$since" ]]; then
        # --since takes precedence
        ks_validate_date "$since" || { echo "Invalid date format: $since" >&2; return 1; }
        echo "$since"
    elif [[ -n "$days" ]]; then
        ks_validate_days "$days" || return 1
        ks_days_to_date "$days"
    else
        # No filtering - return epoch
        echo "1970-01-01T00:00:00Z"
    fi
}

# Collect files modified since a given date
# Usage: ks_collect_files_since "2024-01-01T00:00:00Z"
# Outputs: Array of file paths via global FILES_TO_PROCESS variable
ks_collect_files_since() {
    local since_date="$1"
    local since_epoch=$($KS_DATE -d "$since_date" +%s)
    
    FILES_TO_PROCESS=()
    
    # Add hot log if it has recent events
    if [[ -f "$KS_HOT_LOG" && -s "$KS_HOT_LOG" ]]; then
        # Check if file was modified after since_date
        local file_mtime
        file_mtime=$($KS_STAT -c %Y "$KS_HOT_LOG" 2>/dev/null || echo "0")
        if [[ $file_mtime -ge $since_epoch ]]; then
            FILES_TO_PROCESS+=("$KS_HOT_LOG")
        fi
    fi
    
    # Only check archives modified after since_date
    if [[ -d "$KS_ARCHIVE_DIR" ]]; then
        while IFS= read -r -d '' file; do
            FILES_TO_PROCESS+=("$file")
        done < <($KS_FIND "$KS_ARCHIVE_DIR" -name "*.jsonl" -type f -newermt "$since_date" -print0 2>/dev/null | sort -zr)
    fi
}