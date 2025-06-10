#!/usr/bin/env bash
# Knowledge System Process Library
# Functions for background process management

# Note: This module requires ks_timestamp from core.sh
# Ensure core.sh is sourced before this module

ks_acquire_background_lock() {
    # Acquire exclusive lock for background processing
    # Usage: ks_acquire_background_lock
    # Returns: 0 if lock acquired, 1 if lock exists (another process running)
    
    local lock_file="$KS_BACKGROUND_DIR/background.lock"
    local lock_timeout=300  # 5 minutes
    
    # Check if lock exists and is recent
    if [[ -f "$lock_file" ]]; then
        local lock_age=$(( EPOCHSECONDS - $(stat -c %Y "$lock_file" 2>/dev/null || stat -f %m "$lock_file" 2>/dev/null || echo 0) ))
        
        if [[ "$lock_age" -lt "$lock_timeout" ]]; then
            # Lock is recent, another process is likely running
            return 1
        else
            # Stale lock, remove it
            rm -f "$lock_file"
        fi
    fi
    
    # Acquire lock
    echo "$$:$EPOCHSECONDS:$(whoami)" > "$lock_file"
    return 0
}

ks_release_background_lock() {
    # Release background processing lock
    # Usage: ks_release_background_lock
    
    local lock_file="$KS_BACKGROUND_DIR/background.lock"
    rm -f "$lock_file"
}

ks_register_background_process() {
    # Register a running background process
    # Usage: ks_register_background_process <task_name> <pid> [description]
    
    local task_name="$1"
    local pid="$2"
    local description="${3:-}"
    
    local process_file="$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json"
    
    cat > "$process_file" << EOF
{
  "task": "$task_name",
  "pid": $pid,
  "start_time": "$(ks_timestamp)",
  "start_epoch": $EPOCHSECONDS,
  "description": "$description",
  "status": "running"
}
EOF
}

ks_complete_background_process() {
    # Mark a background process as completed
    # Usage: ks_complete_background_process <task_name> <pid> <status> [output_file]
    
    local task_name="$1"
    local pid="$2"
    local status="$3"  # success or failed
    local output_file="${4:-}"
    
    local active_file="$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json"
    local target_dir="$KS_PROCESS_REGISTRY/$status"
    local target_file="$target_dir/${task_name}-${pid}.json"
    
    if [[ -f "$active_file" ]]; then
        # Add completion information
        local temp_file=$(mktemp)
        jq --arg end_time "$(ks_timestamp)" \
           --arg end_epoch "$EPOCHSECONDS" \
           --arg status "$status" \
           --arg output "$output_file" \
           '. + {end_time: $end_time, end_epoch: ($end_epoch | tonumber), status: $status, output_file: $output}' \
           "$active_file" > "$temp_file"
        
        mv "$temp_file" "$target_file"
        rm -f "$active_file"
    fi
}

ks_cleanup_stale_processes() {
    # Clean up stale process entries
    # Usage: ks_cleanup_stale_processes
    
    local stale_timeout=1800  # 30 minutes
    local current_time=$EPOCHSECONDS
    
    for process_file in "$KS_PROCESS_REGISTRY/active"/*.json; do
        if [[ -f "$process_file" ]]; then
            local start_epoch=$(jq -r '.start_epoch // 0' "$process_file")
            local age=$((current_time - start_epoch))
            
            if [[ "$age" -gt "$stale_timeout" ]]; then
                local task_name=$(jq -r '.task' "$process_file")
                local pid=$(jq -r '.pid' "$process_file")
                
                # Move to failed directory
                ks_complete_background_process "$task_name" "$pid" "failed"
            fi
        fi
    done
}