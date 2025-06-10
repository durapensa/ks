#!/usr/bin/env bats
# Test extract-themes with mocked Claude API

setup() {
    # Export KS_ROOT for absolute paths
    export KS_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    
    # Create temporary test environment
    export TEST_KS_ROOT=$(mktemp -d)
    export KS_HOT_LOG="$TEST_KS_ROOT/hot.jsonl"
    export KS_STATE_DIR="$TEST_KS_ROOT/.background"
    export KS_MOCK_API=1
    
    # Create required directories
    mkdir -p "$KS_STATE_DIR"
    
    # Copy test data
    cp "$BATS_TEST_DIRNAME/fixtures/test_events/minimal_theme_dataset.jsonl" "$KS_HOT_LOG"
    
    # Source environment
    source "$KS_ROOT/.ks-env"
    
    # Override ks_claude function with mock
    ks_claude() {
        cat "$BATS_TEST_DIRNAME/fixtures/claude_responses/themes_minimal_dataset.json"
    }
    export -f ks_claude
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "extract-themes produces expected theme count with mocked Claude" {
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1 --format json
    [ "$status" -eq 0 ]
    
    # Parse and validate expected themes
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 2 ]
    
    # Validate specific theme names
    [[ "$output" == *"Memory System Architecture"* ]]
    [[ "$output" == *"Temporal Knowledge Dynamics"* ]]
}

@test "extract-themes human-readable format with mocked Claude" {
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1
    [ "$status" -eq 0 ]
    
    # Check for expected formatting
    [[ "$output" == *"Theme Analysis"* ]]
    [[ "$output" == *"Events analyzed:"* ]]
    [[ "$output" == *"Memory System Architecture"* ]]
    [[ "$output" == *"Frequency: 3"* ]]
}

@test "extract-themes handles empty dataset gracefully" {
    # Create empty log
    > "$KS_HOT_LOG"
    
    # Mock response for empty dataset
    ks_claude() {
        echo '{"themes": [], "summary": "No themes found in empty dataset"}'
    }
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1 --format json
    [ "$status" -eq 0 ]
    
    # Should return empty themes array
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 0 ]
}

@test "extract-themes with date range filtering" {
    # Add older events that should be filtered out
    local old_date=$(date -d "10 days ago" +%Y%m%d 2>/dev/null || date -v-10d +%Y%m%d)
    local cold_file="$TEST_KS_ROOT/cold-$old_date.jsonl"
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"old","content":"Old thought"}' > "$cold_file"
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 7 --format json
    [ "$status" -eq 0 ]
    
    # Should only analyze recent events
    [[ "$output" == *"Events analyzed: 5"* ]]
}

@test "extract-themes handles mocked API errors gracefully" {
    # Override with error response
    ks_claude() {
        echo "Error: API temporarily unavailable" >&2
        return 1
    }
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Failed"* ]]
}

@test "extract-themes respects event count threshold" {
    # Create log with only 2 events
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"test","content":"Test 1"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"test","content":"Test 2"}' >> "$KS_HOT_LOG"
    
    # Should skip analysis due to low event count (default threshold is 5)
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping analysis"* ]] || [[ "$output" == *"Not enough events"* ]]
}

@test "extract-themes with forced analysis on small dataset" {
    # Create log with only 2 events
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"test","content":"Test 1"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"test","content":"Test 2"}' >> "$KS_HOT_LOG"
    
    # Mock response for small dataset
    ks_claude() {
        echo '{"themes": [{"name": "Test Theme", "description": "Testing", "frequency": 2}]}'
    }
    
    # Force analysis with --force flag
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1 --force --format json
    [ "$status" -eq 0 ]
    
    # Should perform analysis despite low event count
    theme_count=$(echo "$output" | jq '.themes | length')
    [ "$theme_count" -eq 1 ]
}

@test "extract-themes malformed JSON response handling" {
    # Override with malformed response
    ks_claude() {
        echo '{"themes": [{"name": "Incomplete"'
    }
    
    run "$KS_ROOT/tools/analyze/extract-themes" --days 1 --format json
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"Failed"* ]]
}