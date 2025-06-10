#!/usr/bin/env bash
# Knowledge System Events Library
# Functions for event validation and processing

ks_validate_event_type() {
    local type="$1"
    case "$type" in
        thought|connection|question|insight|process)
            return 0
            ;;
        *)
            echo "Error: Invalid event type '$type'" >&2
            echo "Valid types: thought, connection, question, insight, process" >&2
            return 1
            ;;
    esac
}

ks_count_new_events() {
    # Count events added since a given timestamp
    # Usage: ks_count_new_events [since_timestamp]
    # If no timestamp provided, counts all events
    
    local since="${1:-}"
    local count=0
    
    if [[ -f "$KS_HOT_LOG" ]]; then
        if [[ -n "$since" ]]; then
            # Count events newer than timestamp
            count=$(awk -F'"timestamp":"' -v since="$since" '
                $2 {
                    gsub(/".*/, "", $2)
                    if ($2 > since) count++
                }
                END { print count }
            ' "$KS_HOT_LOG")
        else
            # Count all events
            count=$(wc -l < "$KS_HOT_LOG")
        fi
    fi
    
    echo "$count"
}