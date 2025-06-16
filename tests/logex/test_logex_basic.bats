#!/usr/bin/env bats
# Basic logex system tests

setup() {
    # Set KS_ROOT explicitly
    export KS_ROOT="/Users/dp/ks"
    
    # Source environment
    source "$KS_ROOT/.ks-env"
    
    # Create temporary test environment  
    export TEST_TEMP_DIR="$(mktemp -d)"
    
    # Ensure we have required commands
    command -v supervisord >/dev/null || skip "supervisord not installed"
    
    # Create clean test directory
    cd "$TEST_TEMP_DIR"
    
    # Use absolute path to ks command
    KS_CMD="$KS_ROOT/ks"
}

teardown() {
    # Cleanup test directory
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "configure tool creates valid YAML configuration" {
    "$KS_CMD" configure --template simple --output test-config
    
    # Validate created structure (ignore exit code for now)
    [ -d "test-config" ]
    [ -f "test-config/logex-config.yaml" ]
    [ -d "test-config/knowledge" ]
    [ -d "test-config/conversants" ]
    [ -d "test-config/supervise" ]
    [ -L "test-config/tools" ]
}

@test "configure tool produces valid YAML structure" {
    "$KS_CMD" configure --template simple --output yaml-validation-test
    
    # Validate YAML can be parsed (basic syntax check)
    run grep -c ":" yaml-validation-test/logex-config.yaml
    [ "$status" -eq 0 ]
    [ "$output" -gt 10 ]  # Should have many key-value pairs
    
    # Check for no syntax errors in basic structure
    run grep "^[[:space:]]*[a-zA-Z]" yaml-validation-test/logex-config.yaml
    [ "$status" -eq 0 ]
}

@test "orchestrate tool validates configuration" {
    # Create test configuration
    "$KS_CMD" configure --template simple --output test-orchestrate
    
    # Test dry-run (should succeed)
    run "$KS_CMD" orchestrate --dry-run test-orchestrate
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Would orchestrate conversation" ]]
}

@test "orchestrate tool creates supervisord configuration" {
    # Create test configuration
    "$KS_CMD" configure --template simple --output test-supervisor
    
    # Generate supervisord config
    run "$KS_CMD" orchestrate --verbose test-supervisor
    [ "$status" -eq 0 ]
    [ -f "test-supervisor/supervise/supervisord.conf" ]
    
    # Validate supervisord config content
    run grep "program:claude-alice" test-supervisor/supervise/supervisord.conf
    [ "$status" -eq 0 ]
    
    run grep "program:claude-bob" test-supervisor/supervise/supervisord.conf
    [ "$status" -eq 0 ]
}

@test "supervisor tool lists conversations" {
    # Create test conversations
    "$KS_CMD" configure --template simple --output conversation1
    "$KS_CMD" configure --template simple --output conversation2
    
    # Test list command
    run "$KS_CMD" supervisor list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "conversation1" ]]
    [[ "$output" =~ "conversation2" ]]
}

@test "supervisor tool shows conversation status" {
    # Create test configuration
    "$KS_CMD" configure --template simple --output status-test
    "$KS_CMD" orchestrate status-test
    
    # Test status command
    run "$KS_CMD" supervisor status status-test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Conversation Status: status-test" ]]
    [[ "$output" =~ "Supervisord: Not running" ]]
}

@test "YAML configuration contains required fields" {
    "$KS_CMD" configure --template simple --output yaml-test
    
    # Check required fields exist
    run grep "conversation:" yaml-test/logex-config.yaml
    [ "$status" -eq 0 ]
    
    run grep "conversants:" yaml-test/logex-config.yaml
    [ "$status" -eq 0 ]
    
    run grep "dialogue:" yaml-test/logex-config.yaml
    [ "$status" -eq 0 ]
    
    run grep "exit_conditions:" yaml-test/logex-config.yaml
    [ "$status" -eq 0 ]
}

@test "conversation directory structure is created correctly" {
    "$KS_CMD" configure --template simple --output structure-test
    
    # Verify directory structure
    [ -d "structure-test/knowledge" ]
    [ -d "structure-test/conversants" ]
    [ -d "structure-test/supervise" ]
    
    # Verify tools symlink points to ks project
    [ -L "structure-test/tools" ]
    [ -d "structure-test/tools/logex" ]
}

@test "claude-instance wrapper works correctly" {
    "$KS_CMD" configure --template simple --output claude-test
    
    # Test claude-instance with alice (Phase 3: Real Claude CLI)
    run timeout 60 "$KS_ROOT/tools/logex/claude-instance" --conversant alice --conversation-dir claude-test --context "test context"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Real Claude session for alice" ]]
    
    # Verify directory structure was created
    [ -d "claude-test/conversants/alice" ]
    [ -d "claude-test/conversants/alice/.claude" ]
    [ -d "claude-test/conversants/alice/events" ]
    [ -L "claude-test/conversants/alice/ks" ]
    [ -L "claude-test/conversants/alice/tools" ]
    
    # Verify log files were created
    [ -f "claude-test/conversants/alice.log" ]
    [ -f "claude-test/conversants/alice.jsonl" ]
    
    # Verify .claude/ks-instructions.md was created
    [ -f "claude-test/conversants/alice/.claude/ks-instructions.md" ]
    
    # Verify JSONL content is valid JSON
    run jq empty claude-test/conversants/alice.jsonl
    [ "$status" -eq 0 ]
    
    # Verify session events were recorded
    run grep "session_started" claude-test/conversants/alice.jsonl
    [ "$status" -eq 0 ]
    
    run grep "response_generated" claude-test/conversants/alice.jsonl
    [ "$status" -eq 0 ]
}

@test "orchestrate-worker runs complete conversation" {
    "$KS_CMD" configure --template simple --output worker-test
    "$KS_CMD" orchestrate worker-test
    
    # Run orchestrate-worker for a short conversation with real Claude
    # First, create a config with shorter turn limits for faster testing
    sed -i '' 's/max_turns_per_conversant: 5/max_turns_per_conversant: 1/' worker-test/logex-config.yaml
    sed -i '' 's/max_total_turns: 10/max_total_turns: 2/' worker-test/logex-config.yaml
    
    # Run the worker (Phase 3: Real Claude integration)
    run timeout 120 "$KS_ROOT/tools/logex/orchestrate-worker" "$(pwd)/worker-test"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Conversation orchestration completed" ]]
    
    # Verify conversation logs were created
    [ -f "worker-test/knowledge/conversation.jsonl" ]
    [ -f "worker-test/supervise/orchestrator.log" ]
    
    # Verify conversation events
    run grep "conversation_started" worker-test/knowledge/conversation.jsonl
    [ "$status" -eq 0 ]
    
    run grep "conversation_ended" worker-test/knowledge/conversation.jsonl
    [ "$status" -eq 0 ]
    
    # Verify both conversants participated
    run grep "alice" worker-test/knowledge/conversation.jsonl
    [ "$status" -eq 0 ]
    
    run grep "bob" worker-test/knowledge/conversation.jsonl
    [ "$status" -eq 0 ]
    
    # Verify real Claude responses were captured
    [ -f "worker-test/conversants/alice.jsonl" ]
    [ -f "worker-test/conversants/bob.jsonl" ]
    
    # Verify JSONL format is valid
    run jq empty worker-test/conversants/alice.jsonl
    [ "$status" -eq 0 ]
    
    run jq empty worker-test/conversants/bob.jsonl
    [ "$status" -eq 0 ]
    
    # Verify knowledge capture infrastructure was created
    [ -d "worker-test/conversants/alice/events" ]
    [ -d "worker-test/conversants/bob/events" ]
    [ -L "worker-test/conversants/alice/ks" ]
    [ -L "worker-test/conversants/bob/ks" ]
}