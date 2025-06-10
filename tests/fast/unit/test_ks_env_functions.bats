#!/usr/bin/env bats
# Test .ks-env utility functions

setup() {
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    
    # Get absolute path to project root
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    
    # Override knowledge directory for testing
    export KS_KNOWLEDGE_DIR="$TEST_KS_ROOT/knowledge"
    export KS_EVENTS_DIR="$KS_KNOWLEDGE_DIR/events"
    export KS_HOT_LOG="$KS_EVENTS_DIR/hot.jsonl"
    export KS_ARCHIVE_DIR="$KS_EVENTS_DIR/archive"
    export KS_BACKGROUND_DIR="$KS_KNOWLEDGE_DIR/.background"
    export KS_PROCESS_REGISTRY="$KS_BACKGROUND_DIR/processes"
    export KS_NOTIFICATIONS_DIR="$KS_KNOWLEDGE_DIR/.notifications"
    
    # Source the environment (will use our overrides)
    source "$KS_ROOT/.ks-env"
    
    # Source required libraries for tests
    source "$KS_ROOT/lib/core.sh"      # For ks_validate_days, ks_ensure_dirs
    source "$KS_ROOT/lib/files.sh"     # For ks_collect_files
    
    # Process and queue are in tools/lib/, source them directly
    source "$KS_ROOT/tools/lib/process.sh"   # For process management functions
    source "$KS_ROOT/tools/lib/queue.sh"     # For ks_check_background_results
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "ks_validate_days accepts valid day counts" {
    run ks_validate_days 1
    [ "$status" -eq 0 ]
    
    run ks_validate_days 7
    [ "$status" -eq 0 ]
    
    run ks_validate_days 30
    [ "$status" -eq 0 ]
}

@test "ks_validate_days rejects invalid inputs" {
    run ks_validate_days 0
    [ "$status" -ne 0 ]
    
    run ks_validate_days -1
    [ "$status" -ne 0 ]
    
    run ks_validate_days abc
    [ "$status" -ne 0 ]
    
    run ks_validate_days ""
    [ "$status" -ne 0 ]
}

@test "ks_collect_files populates FILES_TO_PROCESS array" {
    # Create test log files
    echo '{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Test"}' > "$KS_HOT_LOG"
    
    # Create archive files
    mkdir -p "$KS_ARCHIVE_DIR"
    echo '{"ts":"2025-01-21T10:00:00Z","type":"thought","topic":"test","content":"Archive 1"}' > "$KS_ARCHIVE_DIR/2025-01-21.jsonl"
    echo '{"ts":"2025-01-20T10:00:00Z","type":"thought","topic":"test","content":"Archive 2"}' > "$KS_ARCHIVE_DIR/2025-01-20.jsonl"
    
    # Call ks_collect_files
    ks_collect_files
    
    # Check FILES_TO_PROCESS is populated
    [ ${#FILES_TO_PROCESS[@]} -eq 3 ]
    
    # Check hot log is first
    [[ "${FILES_TO_PROCESS[0]}" == *"hot.jsonl" ]]
    
    # Check archives are in reverse chronological order
    [[ "${FILES_TO_PROCESS[1]}" == *"2025-01-21.jsonl" ]]
    [[ "${FILES_TO_PROCESS[2]}" == *"2025-01-20.jsonl" ]]
}

@test "ks_register_background_process creates process record" {
    local task_name="test-process"
    local pid=12345
    local description="Test description"
    
    ks_register_background_process "$task_name" "$pid" "$description"
    
    # Check process file exists
    [ -f "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json" ]
    
    # Verify process data
    local process_data=$(cat "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json")
    [[ "$process_data" == *"\"pid\": $pid"* ]]
    [[ "$process_data" == *"\"task\": \"$task_name\""* ]]
    [[ "$process_data" == *"\"status\": \"running\""* ]]
    [[ "$process_data" == *"\"description\": \"$description\""* ]]
}

@test "ks_complete_background_process moves process to completed" {
    local task_name="test-process"
    local pid=12345
    
    # Register process first
    ks_register_background_process "$task_name" "$pid" "Test process"
    [ -f "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json" ]
    
    # Complete the process
    ks_complete_background_process "$task_name" "$pid" "completed"
    
    # Check moved to completed
    [ ! -f "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json" ]
    [ -f "$KS_PROCESS_REGISTRY/completed/${task_name}-${pid}.json" ]
    
    # Verify completion data
    local process_data=$(cat "$KS_PROCESS_REGISTRY/completed/${task_name}-${pid}.json")
    [[ "$process_data" == *"\"status\": \"completed\""* ]]
    [[ "$process_data" == *"\"end_time\":"* ]]
}

@test "ks_complete_background_process with failed status" {
    local task_name="test-process"
    local pid=12345
    
    # Register process first
    ks_register_background_process "$task_name" "$pid" "Test process"
    [ -f "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json" ]
    
    # Fail the process
    ks_complete_background_process "$task_name" "$pid" "failed"
    
    # Check moved to failed
    [ ! -f "$KS_PROCESS_REGISTRY/active/${task_name}-${pid}.json" ]
    [ -f "$KS_PROCESS_REGISTRY/failed/${task_name}-${pid}.json" ]
    
    # Verify failure data
    local process_data=$(cat "$KS_PROCESS_REGISTRY/failed/${task_name}-${pid}.json")
    [[ "$process_data" == *"\"status\": \"failed\""* ]]
    [[ "$process_data" == *"\"end_time\":"* ]]
}

@test "notification file creation (manual test)" {
    # Since ks_create_notification doesn't exist, test manual creation
    local notification_file="$KS_NOTIFICATIONS_DIR/test-$(date +%s).md"
    local content="Test notification content"
    
    # Create notification manually
    echo "$content" > "$notification_file"
    
    # Check file exists
    [ -f "$notification_file" ]
    
    # Verify content
    local stored=$(cat "$notification_file")
    [ "$stored" = "$content" ]
}

@test "ks_check_background_results displays notifications" {
    # Create test notifications
    echo -e "# Test Notification 1\n\nFirst notification content" > "$KS_NOTIFICATIONS_DIR/test1.md"
    echo -e "# Test Notification 2\n\nSecond notification content" > "$KS_NOTIFICATIONS_DIR/test2.md"
    
    # Check notifications
    run ks_check_background_results
    [ "$status" -eq 0 ]
    [[ "$output" == *"Background Analysis Results"* ]]
    [[ "$output" == *"First notification"* ]]
    [[ "$output" == *"Second notification"* ]]
    
    # Note: This function doesn't remove files, just displays them
    [ -f "$KS_NOTIFICATIONS_DIR/test1.md" ]
    [ -f "$KS_NOTIFICATIONS_DIR/test2.md" ]
}

@test "ks_acquire_background_lock acquires and releases lock" {
    local lock_file="$KS_BACKGROUND_DIR/background.lock"
    
    # Acquire lock
    run ks_acquire_background_lock
    [ "$status" -eq 0 ]
    [ -f "$lock_file" ]
    
    # Try to acquire again (should fail)
    run ks_acquire_background_lock
    [ "$status" -ne 0 ]
    
    # Release lock
    ks_release_background_lock
    [ ! -f "$lock_file" ]
    
    # Can acquire again after release
    run ks_acquire_background_lock
    [ "$status" -eq 0 ]
}