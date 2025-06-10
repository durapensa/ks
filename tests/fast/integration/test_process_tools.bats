#!/usr/bin/env bats
# Test process management tools

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
    
    # Source required libraries
    source "$KS_ROOT/lib/core.sh"
    source "$KS_ROOT/tools/lib/process.sh"   # Process library is in tools/lib/
    
    # Create required directories
    mkdir -p "$KS_STATE_DIR/processes/"{active,completed,failed}
    mkdir -p "$KS_NOTIFICATION_DIR"
    mkdir -p "$KS_STATE_DIR/archive"
    mkdir -p "$KS_CONFIG_DIR"
    mkdir -p "$KS_LOG_DIR"
    
    # Create some test data
    echo '{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"test","content":"Test thought"}' > "$KS_HOT_LOG"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "monitor-background-processes shows process status" {
    # Create test process records
    cat > "$KS_STATE_DIR/processes/active/12345.json" << EOF
{
  "pid": 12345,
  "task": "test-active",
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "running"
}
EOF
    
    cat > "$KS_STATE_DIR/processes/completed/12346.json" << EOF
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
    [ "$status" -eq 0 ]
    
    # Should show both processes
    [[ "$output" == *"Active processes: 1"* ]]
    [[ "$output" == *"Completed processes: 1"* ]]
    [[ "$output" == *"test-active"* ]]
}

@test "cleanup-stale-notifications archives old notifications" {
    # Create old and new notifications
    local old_file="$KS_NOTIFICATION_DIR/old_$(date -d "2 days ago" +%s 2>/dev/null || date -v-2d +%s).txt"
    local new_file="$KS_NOTIFICATION_DIR/new_$(date +%s).txt"
    
    echo "Old notification" > "$old_file"
    echo "New notification" > "$new_file"
    
    # Set old timestamp
    touch -t $(date -d "2 days ago" +%Y%m%d%H%M 2>/dev/null || date -v-2d +%Y%m%d%H%M) "$old_file"
    
    # Run cleanup with 1 day retention
    run "$KS_ROOT/tools/plumbing/cleanup-stale-notifications" --days 1
    [ "$status" -eq 0 ]
    
    # Old notification should be archived
    [ ! -f "$old_file" ]
    [ -f "$new_file" ]
    
    # Check archive exists
    archive_count=$(ls -1 "$KS_STATE_DIR/archive" 2>/dev/null | wc -l)
    [ "$archive_count" -gt 0 ]
}

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
    
    # Should have created cold file
    cold_files=$(ls -1 "$TEST_KS_ROOT"/cold-*.jsonl 2>/dev/null | wc -l)
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
    local old_active="$KS_STATE_DIR/processes/active/99999.json"
    local old_completed="$KS_STATE_DIR/processes/completed/88888.json"
    
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
    [ -f "$KS_STATE_DIR/processes/failed/99999.json" ]
    
    # Old completed process might be archived or removed
    # (implementation dependent)
}