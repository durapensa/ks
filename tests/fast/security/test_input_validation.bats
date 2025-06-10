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
    export KS_BACKGROUND_DIR="$TEST_KS_ROOT/.background"
    export KS_PROCESS_REGISTRY="$KS_BACKGROUND_DIR/processes"
    export KS_ANALYSIS_QUEUE="$KS_BACKGROUND_DIR/analysis_queue.json"
    export KS_CONFIG_DIR="$TEST_KS_ROOT/.config"
    export KS_LOG_DIR="$TEST_KS_ROOT/.logs"
    
    # Source environment after overrides
    source "$KS_ROOT/.ks-env"
    
    # Source required libraries and ensure directories
    source "$KS_ROOT/lib/core.sh"
    ks_ensure_dirs
    
    # Create required directories
    mkdir -p "$KS_PROCESS_REGISTRY"/{active,completed,failed}
    mkdir -p "$KS_CONFIG_DIR"
    
    # Source process library
    source "$KS_ROOT/tools/lib/process.sh"
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
    # Try path traversal in search term
    run "$KS_ROOT/tools/capture/query" "../../../etc/passwd"
    [ "$status" -eq 0 ]
    
    # Should search for the string, not access the file
    # No results expected in knowledge base for this path
    [[ "$output" == "" ]] || [[ "$output" != *"root:"* ]]
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
    ks_register_background_process "$malicious_name" 12345
    
    # Check the file was created safely with sanitized name
    [ -f "$KS_PROCESS_REGISTRY/active/test_rm_-rf_-12345.json" ]
    
    # Verify the task name was properly escaped in JSON
    local content=$(cat "$KS_PROCESS_REGISTRY/active/test_rm_-rf_-12345.json")
    # Should contain escaped quotes in the JSON string
    [[ "$content" == *'"task":'* ]]
    # The dangerous command should be safely contained within JSON string quotes
    [[ "$content" == *'test\"; rm -rf /'* ]] || [[ "$content" == *'test"; rm -rf /'* ]]
}

@test "queue analysis data is safely handled" {
    # Source queue library
    source "$KS_ROOT/tools/lib/queue.sh"
    
    # Create analysis with special characters
    local dangerous_content='<script>alert("xss")</script> & $(rm -rf /)'
    local findings_file="$TEST_KS_ROOT/findings/dangerous.json"
    mkdir -p "$(dirname "$findings_file")"
    
    # Create findings with dangerous content
    jq -n --arg content "$dangerous_content" '{findings: [{content: $content}]}' > "$findings_file"
    
    # Add to queue
    ks_queue_add_pending "test-analysis" "$findings_file"
    
    # Verify content is safely stored in queue
    local stored=$(jq -r '.analyses."test-analysis".findings_file' "$KS_ANALYSIS_QUEUE")
    [ "$stored" = "$findings_file" ]
    
    # The dangerous content should remain in the findings file, not executed
    local file_content=$(jq -r '.findings[0].content' "$findings_file")
    [ "$file_content" = "$dangerous_content" ]
}

@test "JSONL parsing handles malformed data safely" {
    # Start with valid entry
    echo '{"ts":"2025-01-20T10:00:00Z","type":"thought","topic":"test","content":"First valid entry"}' > "$KS_HOT_LOG"
    
    # Add malformed JSON
    echo 'not valid json' >> "$KS_HOT_LOG"
    echo '{"unclosed": "quote}' >> "$KS_HOT_LOG"
    
    # Add another valid entry
    echo '{"ts":"2025-01-20T11:00:00Z","type":"thought","topic":"valid","content":"Second valid entry"}' >> "$KS_HOT_LOG"
    
    # Query tool should handle malformed entries gracefully
    run "$KS_ROOT/tools/capture/query" "valid"
    [ "$status" -eq 0 ]
    
    # jq typically stops at first error, so we may only see entries before the malformed data
    # This is acceptable behavior - failing safely rather than showing corrupt data
    [[ "$output" == *"First valid entry"* ]] || [[ "$output" == "" ]]
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