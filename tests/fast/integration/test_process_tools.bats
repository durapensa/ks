#!/usr/bin/env bats
# Test process management tools

setup() {
    # Export KS_ROOT for absolute paths
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    
    # Override all KS environment variables BEFORE sourcing .ks-env
    export KS_KNOWLEDGE_DIR="$TEST_KS_ROOT/knowledge"
    export KS_EVENTS_DIR="$KS_KNOWLEDGE_DIR/events"
    export KS_HOT_LOG="$KS_EVENTS_DIR/hot.jsonl"
    export KS_ARCHIVE_DIR="$KS_EVENTS_DIR/archive"
    export KS_BACKGROUND_DIR="$KS_KNOWLEDGE_DIR/.background"
    export KS_PROCESS_REGISTRY="$KS_BACKGROUND_DIR/processes"
    export KS_ANALYSIS_QUEUE="$KS_BACKGROUND_DIR/analysis_queue.json"
    
    # Source environment after overrides
    source "$KS_ROOT/.ks-env"
    
    # Source required libraries
    source "$KS_ROOT/lib/core.sh"
    source "$KS_ROOT/tools/lib/process.sh"   # Process library is in tools/lib/
    
    # Create required directories using ks_ensure_dirs
    ks_ensure_dirs
    
    # Additional test directories
    mkdir -p "$KS_EVENTS_DIR"
    
    # Create some test data
    echo '{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Test thought"}' > "$KS_HOT_LOG"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "monitor-background-processes shows process status" {
    # Create test process records
    cat > "$KS_PROCESS_REGISTRY/active/test-active-12345.json" << EOF
{
  "pid": 12345,
  "task": "test-active",
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "running"
}
EOF
    
    cat > "$KS_PROCESS_REGISTRY/completed/test-completed-12346.json" << EOF
{
  "pid": 12346,
  "task": "test-completed",
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed",
  "result": "Success"
}
EOF
    
    run "$KS_ROOT/tools/plumbing/monitor-background-processes" --status
    
    # Debug output
    echo "Status: $status" >&2
    echo "Output: $output" >&2
    
    [ "$status" -eq 0 ]
    
    # Should show both processes
    [[ "$output" == *"Active"* ]] && [[ "$output" == *"1"* ]]
    [[ "$output" == *"Completed"* ]] && [[ "$output" == *"1"* ]]
    [[ "$output" == *"test-active"* ]]
}

# cleanup-stale-notifications test removed - tool was deprecated in cleanup commit

@test "rotate-logs handles log rotation" {
    # Create large hot log
    for i in {1..100}; do
        printf '{"ts":"2025-01-22T10:00:%02dZ","type":"thought","topic":"test","content":"Entry %d"}\n' "$i" "$i" >> "$KS_HOT_LOG"
    done
    
    # Get initial line count (should be 101 - 1 from setup + 100 from loop)
    initial_count=$(wc -l < "$KS_HOT_LOG")
    [ "$initial_count" -eq 101 ]
    
    # Run rotation
    run "$KS_ROOT/tools/plumbing/rotate-logs"
    [ "$status" -eq 0 ]
    
    # Hot log should be rotated
    [ -f "$KS_HOT_LOG" ]
    
    # Should have created cold file in archive directory
    cold_files=$(ls -1 "$KS_ARCHIVE_DIR"/cold-*.jsonl 2>/dev/null | wc -l)
    [ "$cold_files" -gt 0 ]
}

@test "validate-jsonl detects valid JSONL format" {
    # Create valid JSONL file
    cat > "$KS_HOT_LOG" << 'EOF'
{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Line 1"}
{"ts":"2025-01-22T10:01:00Z","type":"thought","topic":"test","content":"Line 2"}
{"ts":"2025-01-22T10:02:00Z","type":"thought","topic":"test","content":"Line 3"}
EOF
    
    run "$KS_ROOT/tools/utils/validate-jsonl" "$KS_HOT_LOG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"valid JSON"* ]] || [[ "$output" == *"Valid JSONL"* ]] || [[ "$output" == *"All lines valid"* ]]
}

@test "validate-jsonl detects invalid JSONL format" {
    # Create file with invalid JSON
    cat > "$KS_HOT_LOG" << 'EOF'
{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Valid line"}
not valid json
{"ts":"2025-01-22T10:02:00Z","type":"thought","topic":"test","content":"Another valid line"}
{"unclosed": "quote
EOF
    
    run "$KS_ROOT/tools/utils/validate-jsonl" "$KS_HOT_LOG"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid"* ]] || [[ "$output" == *"invalid"* ]]
    [[ "$output" == *"Line 2"* ]]
    [[ "$output" == *"Line 4"* ]]
}

@test "process cleanup removes stale process files" {
    # Create old process files
    local old_active="$KS_PROCESS_REGISTRY/active/old-task-99999.json"
    local old_completed="$KS_PROCESS_REGISTRY/completed/old-task-88888.json"
    
    cat > "$old_active" << EOF
{
  "pid": 99999,
  "task": "stale-process",
  "start_time": "2025-01-01T10:00:00Z",
  "status": "running"
}
EOF
    
    cat > "$old_completed" << EOF
{
  "pid": 88888,
  "task": "old-completed",
  "start_time": "2025-01-01T10:00:00Z",
  "end_time": "2025-01-01T11:00:00Z",
  "status": "completed"
}
EOF
    
    # Set old timestamps
    touch -t $(date -d "30 days ago" +%Y%m%d%H%M 2>/dev/null || date -v-30d +%Y%m%d%H%M) "$old_active"
    touch -t $(date -d "30 days ago" +%Y%m%d%H%M 2>/dev/null || date -v-30d +%Y%m%d%H%M) "$old_completed"
    
    # Run monitor with cleanup
    run "$KS_ROOT/tools/plumbing/monitor-background-processes" --cleanup
    [ "$status" -eq 0 ]
    
    # Stale active process should be moved to failed
    [ ! -f "$old_active" ]
    [ -f "$KS_PROCESS_REGISTRY/failed/old-task-99999.json" ]
    
    # Old completed process might be archived or removed
    # (implementation dependent)
}