#!/usr/bin/env bash
# Analysis helper functions extracted from lib/argparse.sh

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