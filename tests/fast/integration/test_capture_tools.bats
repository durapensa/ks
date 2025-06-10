#!/usr/bin/env bats
# Test capture tools (events, query)

setup() {
    # Export KS_ROOT for absolute paths
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    
    # Override knowledge directory for testing
    export KS_KNOWLEDGE_DIR="$TEST_KS_ROOT/knowledge"
    export KS_EVENTS_DIR="$KS_KNOWLEDGE_DIR/events"
    export KS_HOT_LOG="$KS_EVENTS_DIR/hot.jsonl"
    export KS_ARCHIVE_DIR="$KS_EVENTS_DIR/archive"
    export KS_BACKGROUND_DIR="$KS_KNOWLEDGE_DIR/.background"
    export KS_PROCESS_REGISTRY="$KS_BACKGROUND_DIR/processes"
    export KS_NOTIFICATIONS_DIR="$KS_KNOWLEDGE_DIR/.notifications"
    
    # Source environment (will use our overrides)
    source "$KS_ROOT/.ks-env"
    
    # Source required library and ensure directories
    source "$KS_ROOT/lib/core.sh"
    ks_ensure_dirs
    
    # Create test data with recent timestamps
    local today=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local yesterday=$(date -u -d "yesterday" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1d +%Y-%m-%dT%H:%M:%SZ)
    cat > "$KS_HOT_LOG" << EOF
{"ts":"$yesterday","type":"thought","topic":"memory","content":"Human memory is associative"}
{"ts":"$yesterday","type":"thought","topic":"systems","content":"Complex systems have emergent properties"}
{"ts":"$today","type":"insight","topic":"memory","content":"Memory and time are intertwined"}
{"ts":"$today","type":"connection","topic":"patterns","content":"Patterns repeat across scales"}
{"ts":"$today","type":"thought","topic":"knowledge","content":"Knowledge graphs mirror neural networks"}
EOF
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "events tool validates arguments" {
    # Test with no arguments (should fail)
    run "$KS_ROOT/tools/capture/events"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: ke"* ]]
    
    # Test with valid arguments
    run "$KS_ROOT/tools/capture/events" thought testing "Test content"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Event logged: thought/testing"* ]]
}

@test "events tool validates event types" {
    # Test with invalid event type
    run "$KS_ROOT/tools/capture/events" invalid testing "Test content"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid event type"* ]]
    
    # Test with valid event type
    run "$KS_ROOT/tools/capture/events" insight testing "Test insight"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Event logged: insight/testing"* ]]
}

@test "events tool handles stdin input" {
    # Test piping content to events tool
    run bash -c "echo 'Piped content' | $KS_ROOT/tools/capture/events thought testing"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Event logged: thought/testing"* ]]
    
    # Verify event was written to log
    local last_event=$(tail -n1 "$KS_HOT_LOG")
    [[ "$last_event" == *"Piped content"* ]]
}

@test "query tool searches by pattern" {
    run "$KS_ROOT/tools/capture/query" "memory"
    [ "$status" -eq 0 ]
    
    # Should find entries containing "memory"
    [[ "$output" == *"Human memory is associative"* ]]
    [[ "$output" == *"Memory and time are intertwined"* ]]
    
    # Should not show unrelated entries
    [[ "$output" != *"Complex systems"* ]]
    [[ "$output" != *"Patterns repeat"* ]]
}

@test "query tool searches across date range" {
    # Create older cold file in archive directory
    local old_date=$(date -d "3 days ago" +%Y%m%d 2>/dev/null || date -v-3d +%Y%m%d)
    local cold_file="$KS_ARCHIVE_DIR/cold-$old_date.jsonl"
    local old_timestamp=$(date -u -d "3 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-3d +%Y-%m-%dT%H:%M:%SZ)
    
    cat > "$cold_file" << EOF
{"ts":"$old_timestamp","type":"thought","topic":"memory","content":"Old memory thought"}
EOF
    
    # Search with date range
    local since_date=$(date -u -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)
    run "$KS_ROOT/tools/capture/query" "memory" --since "$since_date"
    [ "$status" -eq 0 ]
    
    # Should find entries from both files
    [[ "$output" == *"Old memory thought"* ]]
    [[ "$output" == *"Human memory is associative"* ]]
    [[ "$output" == *"Memory and time are intertwined"* ]]
}

@test "query tool output format" {
    # Query tool outputs text format, not JSON
    run "$KS_ROOT/tools/capture/query" "memory"
    [ "$status" -eq 0 ]
    
    # Should output timestamped entries
    [[ "$output" == *"["*"/"*"]"* ]]
    
    # Should find memory-related entries
    [[ "$output" == *"memory"* ]]
}

@test "query tool handles special characters" {
    # Add entry with special characters
    echo '{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Special chars: $test & \"quotes\""}' >> "$KS_HOT_LOG"
    
    run "$KS_ROOT/tools/capture/query" "Special chars"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Special chars"* ]]
}

@test "query tool with type filter" {
    run "$KS_ROOT/tools/capture/query" --type thought "memory"
    [ "$status" -eq 0 ]
    
    # Should only show thoughts
    [[ "$output" == *"Human memory is associative"* ]]
    
    # Should not show insight
    [[ "$output" != *"Memory and time are intertwined"* ]]
}

@test "query tool case insensitive search" {
    run "$KS_ROOT/tools/capture/query" "MEMORY"
    [ "$status" -eq 0 ]
    
    # Should find entries despite case difference
    [[ "$output" == *"Human memory is associative"* ]]
    [[ "$output" == *"Memory and time are intertwined"* ]]
}