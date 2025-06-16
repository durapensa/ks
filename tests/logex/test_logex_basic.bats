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