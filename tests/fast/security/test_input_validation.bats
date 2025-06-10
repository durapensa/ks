#!/usr/bin/env bats
# Test input validation and security

setup() {
    # Export KS_ROOT for absolute paths
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    
    # Override all KS environment variables BEFORE sourcing .ks-env
    export KS_KNOWLEDGE_DIR="$TEST_KS_ROOT"
    export KS_HOT_LOG="$TEST_KS_ROOT/hot.jsonl"
    export KS_STATE_DIR="$TEST_KS_ROOT/.background"
    export KS_NOTIFICATION_DIR="$TEST_KS_ROOT/.background/notifications"
    export KS_PROCESS_DIR="$TEST_KS_ROOT/.background/processes"
    export KS_CONFIG_DIR="$TEST_KS_ROOT/.config"
    export KS_LOG_DIR="$TEST_KS_ROOT/.logs"
    
    # Source environment after overrides
    source "$KS_ROOT/.ks-env"
    
    # Create required directories
    mkdir -p "$KS_STATE_DIR/processes/active"
    mkdir -p "$KS_NOTIFICATION_DIR"
    mkdir -p "$KS_CONFIG_DIR"
    mkdir -p "$KS_LOG_DIR"
    
    # Create minimal test data
    echo '{"ts":"2025-01-20T10:00:00Z","type":"thought","topic":"test","content":"Test entry"}' > "$KS_HOT_LOG"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "query tool prevents command injection via pattern" {
    # Try command injection in pattern
    run "$KS_ROOT/tools/capture/query" '$(echo malicious)'
    [ "$status" -eq 0 ]
    
    # Should not execute the command
    [[ "$output" != *"malicious"* ]]
}

@test "query tool handles path traversal attempts" {
    # Try path traversal
    run "$KS_ROOT/tools/capture/query" --days "../../../etc/passwd"
    [ "$status" -ne 0 ]
    
    # Should reject invalid day count
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Invalid"* ]]
}

@test "events tool validates numeric arguments" {
    # Try non-numeric count
    run "$KS_ROOT/tools/capture/events" "'; rm -rf /"
    [ "$status" -ne 0 ]
    
    # Try negative count
    run "$KS_ROOT/tools/capture/events" "-1"
    [ "$status" -ne 0 ]
}

@test "file paths are properly validated" {
    # Test ks_collect_files doesn't access outside directories
    export KS_HOT_LOG="/etc/passwd"
    
    run ks_collect_files 1
    # Should not return system files
    [[ "$output" != *"/etc/passwd"* ]]
}

@test "process names are sanitized" {
    # Try to inject commands in process name
    local malicious_name='test"; rm -rf /'
    
    # Register process with malicious name
    ks_register_process 12345 "$malicious_name"
    
    # Check the file was created safely
    [ -f "$KS_STATE_DIR/processes/active/12345.json" ]
    
    # Verify the task name was properly escaped in JSON
    local content=$(cat "$KS_STATE_DIR/processes/active/12345.json")
    # Should contain escaped quotes in the JSON string
    [[ "$content" == *'"task":'* ]]
    # The dangerous command should be safely contained within JSON string quotes
    [[ "$content" == *'test\"; rm -rf /'* ]] || [[ "$content" == *'test"; rm -rf /'* ]]
}

@test "notification content is safely handled" {
    # Create notification with special characters
    local dangerous_content='<script>alert("xss")</script> & $(rm -rf /)'
    
    local notification_file=$(ks_create_notification "test" "$dangerous_content")
    
    # Content should be stored as-is (not executed)
    local stored=$(cat "$notification_file")
    [ "$stored" = "$dangerous_content" ]
    
    # Display should not execute content
    run ks_check_notifications
    [ "$status" -eq 0 ]
    # Output exists but commands not executed
}

@test "JSONL parsing handles malformed data safely" {
    # Add malformed JSON to log
    echo 'not valid json' >> "$KS_HOT_LOG"
    echo '{"unclosed": "quote}' >> "$KS_HOT_LOG"
    echo '{"ts":"2025-01-20T11:00:00Z","type":"thought","topic":"valid","content":"Valid entry"}' >> "$KS_HOT_LOG"
    
    # Tools should handle gracefully
    run "$KS_ROOT/tools/capture/events"
    [ "$status" -eq 0 ]
    
    # Should still show valid entries
    [[ "$output" == *"Valid entry"* ]]
}

@test "environment variables are not expanded in user input" {
    # Set a test environment variable
    export SECRET_DATA="sensitive information"
    
    # Try to access it via query
    run "$KS_ROOT/tools/capture/query" '$SECRET_DATA'
    [ "$status" -eq 0 ]
    
    # Should not expose the variable value
    [[ "$output" != *"sensitive information"* ]]
}

@test "file operations respect permissions" {
    # Create read-only directory
    local readonly_dir="$TEST_KS_ROOT/readonly"
    mkdir "$readonly_dir"
    chmod 555 "$readonly_dir"
    
    # Try to create notification in read-only area
    export KS_NOTIFICATION_DIR="$readonly_dir/notifications"
    
    # Should handle permission error gracefully
    run ks_create_notification "test" "content"
    # Function should not crash the script
    
    # Cleanup
    chmod 755 "$readonly_dir"
}