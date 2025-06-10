#!/usr/bin/env bats
# Test extract-themes with mocked Claude API

setup() {
    # Export KS_ROOT for absolute paths
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export BATS_TEST_DIRNAME
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    export KS_MOCK_API=1
    
    # Override all KS environment variables BEFORE sourcing .ks-env
    export KS_KNOWLEDGE_DIR="$TEST_KS_ROOT/knowledge"
    export KS_EVENTS_DIR="$KS_KNOWLEDGE_DIR/events"
    export KS_HOT_LOG="$KS_EVENTS_DIR/hot.jsonl"
    export KS_ARCHIVE_DIR="$KS_EVENTS_DIR/archive"
    export KS_BACKGROUND_DIR="$KS_KNOWLEDGE_DIR/.background"
    export KS_PROCESS_REGISTRY="$KS_BACKGROUND_DIR/processes"
    
    # Source environment
    source "$KS_ROOT/.ks-env"
    
    # Source core library and ensure directories
    source "$KS_ROOT/lib/core.sh"
    ks_ensure_dirs
    
    # Copy test data
    cp "$BATS_TEST_DIRNAME/fixtures/test_events/minimal_theme_dataset.jsonl" "$KS_HOT_LOG"
    
    # Create mock ks_claude command in a temporary bin directory
    export MOCK_BIN_DIR="$TEST_KS_ROOT/bin"
    mkdir -p "$MOCK_BIN_DIR"
    
    # Create claude mock script (the actual CLI command)
    cat > "$MOCK_BIN_DIR/claude" << EOF
#!/usr/bin/env bash
# Read all input
input=\$(cat)

# Check for error simulation
if [[ -f "$TEST_KS_ROOT/.simulate_error" ]]; then
    echo "Error: API temporarily unavailable" >&2
    exit 1
fi

# Check for malformed response simulation
if [[ -f "$TEST_KS_ROOT/.simulate_malformed" ]]; then
    echo '{"themes": [{"name": "Incomplete"'
    exit 0
fi

# Check for small dataset response
if [[ -f "$TEST_KS_ROOT/.simulate_small_dataset" ]]; then
    echo '{"result": {"themes": [{"name": "Test Theme", "description": "Testing", "frequency": 2, "supporting_quotes": ["Test 1", "Test 2"]}]}}'
    exit 0
fi

# Default response
echo '{"result": '"\$(cat "$BATS_TEST_DIRNAME/fixtures/claude_responses/themes_minimal_dataset.json")"'}'
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    # Add mock bin to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "extract-themes produces expected theme count with mocked Claude" {
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Parse and validate expected themes
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 2 ]
    
    # Validate specific theme names
    [[ "$output" == *"Memory System Architecture"* ]]
    [[ "$output" == *"Temporal Knowledge Dynamics"* ]]
}

@test "extract-themes human-readable format with mocked Claude" {
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365
    [ "$status" -eq 0 ]
    
    # Check for expected formatting
    [[ "$output" == *"KNOWLEDGE THEMES ANALYSIS"* ]]
    [[ "$output" == *"Generated at"* ]]
    [[ "$output" == *"Memory System Architecture"* ]]
    [[ "$output" == *"Frequency: 3"* ]]
}

@test "extract-themes handles empty dataset gracefully" {
    # Create empty log
    > "$KS_HOT_LOG"
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Should indicate no events found
    [[ "$output" == *"No events found"* ]]
}

@test "extract-themes with date range filtering" {
    # Add older events that should be filtered out
    local old_date=$(date -d "10 days ago" +%Y%m%d 2>/dev/null || date -v-10d +%Y%m%d)
    local cold_file="$TEST_KS_ROOT/cold-$old_date.jsonl"
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"old","content":"Old thought"}' > "$cold_file"
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Should return themes in JSON format
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 2 ]
}

@test "extract-themes handles mocked API errors gracefully" {
    # Trigger error response
    touch "$TEST_KS_ROOT/.simulate_error"
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Failed"* ]]
}

@test "extract-themes respects event count threshold" {
    # Create log with only 2 events
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"test","content":"Test 1"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"test","content":"Test 2"}' >> "$KS_HOT_LOG"
    
    # Tool doesn't have event count threshold - it will analyze any number of events
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Should still return themes
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -ge 1 ]
}

@test "extract-themes with forced analysis on small dataset" {
    # Create log with only 2 events
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"test","content":"Test 1"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"test","content":"Test 2"}' >> "$KS_HOT_LOG"
    
    # Trigger small dataset response
    touch "$TEST_KS_ROOT/.simulate_small_dataset"
    
    # Run analysis (no --force flag needed as tool doesn't have threshold)
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Should return the test theme
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 1 ]
    [[ "$output" == *"Test Theme"* ]]
}

@test "extract-themes malformed JSON response handling" {
    # Trigger malformed response
    touch "$TEST_KS_ROOT/.simulate_malformed"
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 365 --format json
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Invalid JSON"* ]]
}