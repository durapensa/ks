#!/usr/bin/env bats
# Test find-connections with mocked Claude API

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
    cp "$BATS_TEST_DIRNAME/fixtures/test_events/connection_dataset.jsonl" "$KS_HOT_LOG"
    
    # Create mock ks_claude command in a temporary bin directory
    export MOCK_BIN_DIR="$TEST_KS_ROOT/bin"
    mkdir -p "$MOCK_BIN_DIR"
    
    # Create claude mock script (the actual CLI command)
    cat > "$MOCK_BIN_DIR/claude" << EOF
#!/usr/bin/env bash
# Read all input
input=\$(cat)
# Return mock response wrapped as Claude CLI would
echo '{"result": '"\$(cat "$BATS_TEST_DIRNAME/fixtures/claude_responses/connections_dataset.json")"'}'
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    # Add mock bin to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"
}

teardown() {
    # Clean up temporary directory
    [[ -d "$TEST_KS_ROOT" ]] && rm -rf "$TEST_KS_ROOT"
}

@test "find-connections identifies expected connections with mocked Claude" {
    run "$KS_ROOT/tools/analyze/find-connections" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Parse and validate connections
    connection_count=$(echo "$output" | jq '.connections | length')
    [ "$connection_count" -eq 2 ]
    
    # Validate specific connections
    [[ "$output" == *"Scale-invariant patterns"* ]]
    [[ "$output" == *"Emergence through pattern recognition"* ]]
}

@test "find-connections human-readable format with mocked Claude" {
    run "$KS_ROOT/tools/analyze/find-connections" --days 365
    [ "$status" -eq 0 ]
    
    # Check for expected formatting
    [[ "$output" == *"KNOWLEDGE CONNECTIONS ANALYSIS"* ]]
    [[ "$output" == *"Generated at"* ]]
    [[ "$output" == *"Connected:"* ]]
    [[ "$output" == *"Strength:"* ]]
}

@test "find-connections with pattern filter" {
    # Test with specific pattern focus
    ks_claude() {
        # Mock response for pattern-focused query
        echo '{
            "connections": [{
                "entries": ["patterns", "emergence"],
                "relationship": "Pattern-based emergence",
                "insight": "Patterns drive emergent phenomena",
                "strength": "strong"
            }]
        }'
    }
    
    run "$KS_ROOT/tools/analyze/find-connections" --days 365 --pattern "pattern" --format json
    [ "$status" -eq 0 ]
    
    # Should find pattern-related connections
    connection_count=$(echo "$output" | jq '.connections | length')
    [ "$connection_count" -eq 1 ]
    [[ "$output" == *"Pattern-based emergence"* ]]
}

@test "find-connections handles no connections gracefully" {
    # Create unrelated events
    cat > "$KS_HOT_LOG" << 'EOF'
{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"weather","content":"It is raining today"}
{"ts":"2025-01-01T11:00:00Z","type":"thought","topic":"food","content":"I had pizza for lunch"}
EOF
    
    # Mock response for unconnected dataset
    ks_claude() {
        echo '{"connections": [], "summary": "No significant connections found between entries"}'
    }
    
    run "$KS_ROOT/tools/analyze/find-connections" --days 365 --format json
    [ "$status" -eq 0 ]
    
    # Should return empty connections array
    connection_count=$(echo "$output" | jq '.connections | length')
    [ "$connection_count" -eq 0 ]
}

@test "find-connections respects minimum event threshold" {
    # Create log with only 2 events
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"test","content":"Test 1"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"test","content":"Test 2"}' >> "$KS_HOT_LOG"
    
    # Should skip analysis due to low event count
    run "$KS_ROOT/tools/analyze/find-connections" --days 365
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping analysis"* ]] || [[ "$output" == *"Not enough events"* ]]
}

@test "find-connections with forced analysis" {
    # Create minimal dataset
    echo '{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"A","content":"Concept A"}' > "$KS_HOT_LOG"
    echo '{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"B","content":"Concept B"}' >> "$KS_HOT_LOG"
    
    # Mock response for forced analysis
    ks_claude() {
        echo '{"connections": [{"entries": ["A", "B"], "relationship": "Basic connection", "strength": "weak"}]}'
    }
    
    # Force analysis
    run "$KS_ROOT/tools/analyze/find-connections" --days 365 --force --format json
    [ "$status" -eq 0 ]
    
    # Should perform analysis
    connection_count=$(echo "$output" | jq '.connections | length')
    [ "$connection_count" -eq 1 ]
}

@test "find-connections connection strength filtering" {
    # Mock response with various strength connections
    ks_claude() {
        echo '{
            "connections": [
                {"entries": ["A", "B"], "relationship": "Strong link", "strength": "strong"},
                {"entries": ["C", "D"], "relationship": "Weak link", "strength": "weak"}
            ]
        }'
    }
    
    run "$KS_ROOT/tools/analyze/find-connections" --days 365 --min-strength strong --format json
    [ "$status" -eq 0 ]
    
    # Should only show strong connections
    [[ "$output" == *"Strong link"* ]]
    [[ "$output" != *"Weak link"* ]]
}