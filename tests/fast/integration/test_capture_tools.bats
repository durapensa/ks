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
    
    # Create test data
    cat > "$KS_HOT_LOG" << 'EOF'
{"ts":"2025-01-20T10:00:00Z","type":"thought","topic":"memory","content":"Human memory is associative"}
{"ts":"2025-01-20T11:00:00Z","type":"thought","topic":"systems","content":"Complex systems have emergent properties"}
{"ts":"2025-01-21T09:00:00Z","type":"insight","topic":"memory","content":"Memory and time are intertwined"}
{"ts":"2025-01-21T14:00:00Z","type":"connection","topic":"patterns","content":"Patterns repeat across scales"}
{"ts":"2025-01-22T08:00:00Z","type":"thought","topic":"knowledge","content":"Knowledge graphs mirror neural networks"}
EOF
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "events tool displays recent entries" {
    run "$KS_ROOT/tools/capture/events"
    [ "$status" -eq 0 ]
    
    # Should show all 5 events by default
    [[ "$output" == *"Human memory is associative"* ]]
    [[ "$output" == *"Complex systems have emergent properties"* ]]
    [[ "$output" == *"Memory and time are intertwined"* ]]
    [[ "$output" == *"Patterns repeat across scales"* ]]
    [[ "$output" == *"Knowledge graphs mirror neural networks"* ]]
}

@test "events tool respects count limit" {
    run "$KS_ROOT/tools/capture/events" 2
    [ "$status" -eq 0 ]
    
    # Should show only last 2 events
    [[ "$output" == *"Patterns repeat across scales"* ]]
    [[ "$output" == *"Knowledge graphs mirror neural networks"* ]]
    
    # Should not show older events
    [[ "$output" != *"Human memory is associative"* ]]
    [[ "$output" != *"Complex systems have emergent properties"* ]]
}

@test "events tool handles empty log gracefully" {
    # Create empty log
    > "$KS_HOT_LOG"
    
    run "$KS_ROOT/tools/capture/events"
    [ "$status" -eq 0 ]
    # Should not error on empty log
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
    # Create older cold file
    local old_date=$(date -d "3 days ago" +%Y%m%d 2>/dev/null || date -v-3d +%Y%m%d)
    local cold_file="$TEST_KS_ROOT/cold-$old_date.jsonl"
    
    cat > "$cold_file" << 'EOF'
{"ts":"2025-01-19T10:00:00Z","type":"thought","topic":"memory","content":"Old memory thought"}
EOF
    
    # Search with 7 day range
    run "$KS_ROOT/tools/capture/query" --days 7 "memory"
    [ "$status" -eq 0 ]
    
    # Should find entries from both files
    [[ "$output" == *"Old memory thought"* ]]
    [[ "$output" == *"Human memory is associative"* ]]
    [[ "$output" == *"Memory and time are intertwined"* ]]
}

@test "query tool with json output" {
    run "$KS_ROOT/tools/capture/query" --format json "memory"
    [ "$status" -eq 0 ]
    
    # Output should be valid JSON array
    echo "$output" | jq . >/dev/null 2>&1
    [ $? -eq 0 ]
    
    # Should have correct structure
    local count=$(echo "$output" | jq 'length')
    [ "$count" -eq 2 ]
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