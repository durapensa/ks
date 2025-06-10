#!/usr/bin/env bash
# Knowledge System Queue Library
# Functions for managing the background analysis queue

# Note: This module requires ks_timestamp from core.sh
# Ensure core.sh is sourced before this module

ks_queue_init() {
    # Initialize analysis queue if it doesn't exist
    # Usage: ks_queue_init
    
    if [[ ! -f "$KS_ANALYSIS_QUEUE" ]]; then
        echo '{"analyses": {}}' > "$KS_ANALYSIS_QUEUE"
    fi
}

ks_queue_check() {
    # Check if an analysis type has pending review
    # Usage: ks_queue_check <analysis_type>
    # Returns: 0 if clear to run, 1 if pending review
    
    local analysis_type="$1"
    ks_queue_init
    
    local status=$(jq -r ".analyses.\"$analysis_type\".status // \"none\"" "$KS_ANALYSIS_QUEUE")
    
    if [[ "$status" == "pending_review" ]]; then
        return 1  # Cannot run - has pending review
    fi
    return 0  # Clear to run
}

ks_queue_add_pending() {
    # Add analysis to queue as pending review
    # Usage: ks_queue_add_pending <analysis_type> <findings_file>
    
    local analysis_type="$1"
    local findings_file="$2"
    ks_queue_init
    
    local temp_file=$(mktemp)
    jq --arg type "$analysis_type" \
       --arg file "$findings_file" \
       --arg time "$(ks_timestamp)" \
       '.analyses[$type] = {status: "pending_review", findings_file: $file, completed_at: $time}' \
       "$KS_ANALYSIS_QUEUE" > "$temp_file"
    
    mv "$temp_file" "$KS_ANALYSIS_QUEUE"
}

ks_queue_clear() {
    # Clear analysis from queue after review
    # Usage: ks_queue_clear <analysis_type>
    
    local analysis_type="$1"
    ks_queue_init
    
    local temp_file=$(mktemp)
    jq --arg type "$analysis_type" \
       'del(.analyses[$type])' \
       "$KS_ANALYSIS_QUEUE" > "$temp_file"
    
    mv "$temp_file" "$KS_ANALYSIS_QUEUE"
}

ks_queue_list_pending() {
    # List all analyses pending review
    # Usage: ks_queue_list_pending
    # Output: JSON array of pending analyses
    
    ks_queue_init
    jq -r '.analyses | to_entries | map(select(.value.status == "pending_review")) | map({type: .key, value: .value})' "$KS_ANALYSIS_QUEUE"
}

ks_check_background_results() {
    # Check for pending analyses in queue and display notification
    # Usage: ks_check_background_results
    # Returns: 0 if notifications displayed, 1 if none found
    
    # Initialize queue if needed
    ks_queue_init
    
    # Check for pending analyses
    local pending=$(ks_queue_list_pending)
    
    if [[ "$pending" == "[]" ]]; then
        return 1
    fi
    
    # Display pending analyses
    echo ""
    echo "=== Background Analyses Ready for Review ==="
    echo ""
    
    local count=$(jq -r 'length' <<< "$pending")
    echo "You have $count analysis/analyses pending review:"
    echo ""
    
    jq -r '.[] | "  • \(.type) - completed at \(.value.completed_at)"' <<< "$pending"
    
    echo ""
    echo "Run 'tools/workflow/review-findings' in a separate terminal to review."
    echo "============================================"
    echo ""
    
    return 0
}