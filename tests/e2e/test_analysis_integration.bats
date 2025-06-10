#!/usr/bin/env bats
# End-to-end tests with real Claude API

setup() {
    # Skip if no API key
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        skip "ANTHROPIC_API_KEY not set"
    fi
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    export KS_HOT_LOG="$TEST_KS_ROOT/hot.jsonl"
    export KS_STATE_DIR="$TEST_KS_ROOT/.background"
    export KS_E2E_TEST=1
    
    # Create required directories
    mkdir -p "$KS_STATE_DIR"
    
    # Create minimal test dataset (5 events to minimize API usage)
    cat > "$KS_HOT_LOG" << 'EOF'
{"ts":"2025-01-22T10:00:00Z","type":"thought","topic":"systems","content":"Complex systems exhibit emergent properties"}
{"ts":"2025-01-22T10:30:00Z","type":"thought","topic":"patterns","content":"Patterns repeat across different scales"}
{"ts":"2025-01-22T11:00:00Z","type":"insight","topic":"emergence","content":"Emergence arises from simple interactions"}
{"ts":"2025-01-22T11:30:00Z","type":"connection","topic":"complexity","content":"Complexity emerges from simplicity"}
{"ts":"2025-01-22T12:00:00Z","type":"thought","topic":"fractals","content":"Fractals demonstrate scale invariance"}
EOF
    
    # Source environment
    source "$BATS_TEST_DIRNAME/../../.ks-env"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "extract-themes with real Claude API" {
    run "$BATS_TEST_DIRNAME/../../tools/analyze/extract-themes" --days 1 --format json
    [ "$status" -eq 0 ]
    
    # Verify valid JSON output
    echo "$output" | jq . >/dev/null 2>&1
    [ $? -eq 0 ]
    
    # Should have themes array
    themes=$(echo "$output" | jq '.themes')
    [ "$themes" != "null" ]
    
    # Should have analyzed our 5 events
    [[ "$output" == *"Events analyzed: 5"* ]] || [[ "$output" == *"\"event_count\": 5"* ]]
}

@test "find-connections with real Claude API" {
    run "$BATS_TEST_DIRNAME/../../tools/analyze/find-connections" --days 1 --format json
    [ "$status" -eq 0 ]
    
    # Verify valid JSON output
    echo "$output" | jq . >/dev/null 2>&1
    [ $? -eq 0 ]
    
    # Should have connections array
    connections=$(echo "$output" | jq '.connections')
    [ "$connections" != "null" ]
}

@test "background analysis integration with real Claude" {
    # Test the full background analysis flow
    run "$BATS_TEST_DIRNAME/../../tools/plumbing/schedule-analysis-cycles" --force --type theme
    [ "$status" -eq 0 ]
    
    # Should create background process
    [[ "$output" == *"Starting background theme analysis"* ]]
    
    # Wait a moment for process to register
    sleep 2
    
    # Check process was registered
    [ -d "$KS_STATE_DIR/processes/active" ]
    active_count=$(ls -1 "$KS_STATE_DIR/processes/active" 2>/dev/null | wc -l)
    [ "$active_count" -gt 0 ]
}

@test "API error handling with invalid model" {
    # Test with invalid model to trigger API error
    export KS_MODEL="invalid-model-name"
    
    run "$BATS_TEST_DIRNAME/../../tools/analyze/extract-themes" --days 1
    [ "$status" -ne 0 ]
    
    # Should show error message
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Failed"* ]]
}

@test "concurrent analysis requests" {
    # Test running multiple analyses in parallel
    "$BATS_TEST_DIRNAME/../../tools/analyze/extract-themes" --days 1 --format json > "$TEST_KS_ROOT/themes.out" &
    pid1=$!
    
    "$BATS_TEST_DIRNAME/../../tools/analyze/find-connections" --days 1 --format json > "$TEST_KS_ROOT/connections.out" &
    pid2=$!
    
    # Wait for both to complete
    wait $pid1
    themes_status=$?
    wait $pid2
    connections_status=$?
    
    # Both should succeed
    [ "$themes_status" -eq 0 ]
    [ "$connections_status" -eq 0 ]
    
    # Both should produce valid output
    [ -s "$TEST_KS_ROOT/themes.out" ]
    [ -s "$TEST_KS_ROOT/connections.out" ]
}