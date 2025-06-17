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
    # Context-aware: uses local hot.jsonl if in conversation directory
    
    local since="${1:-}"
    local count=0
    
    # Determine which hot.jsonl to use (conversation-local or global)
    local hot_log_file="$KS_HOT_LOG"
    if [[ -f "$KS_CONVERSATION_HOT_LOG" ]]; then
        hot_log_file="$KS_CONVERSATION_HOT_LOG"
    fi
    
    if [[ -f "$hot_log_file" ]]; then
        if [[ -n "$since" ]]; then
            # Count events newer than timestamp
            count=$(awk -F'"timestamp":"' -v since="$since" '
                $2 {
                    gsub(/".*/, "", $2)
                    if ($2 > since) count++
                }
                END { print count }
            ' "$hot_log_file")
        else
            # Count all events
            count=$(wc -l < "$hot_log_file" | tr -d ' ')
        fi
    fi
    
    echo "$count"
}