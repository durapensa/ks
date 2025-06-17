#!/usr/bin/env bash
# Run end-to-end tests with real Claude API

set -euo pipefail

# Source environment for KS_* variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.ks-env"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: bats-core is not installed"
    echo "Run: ./tests/setup_test_framework.sh"
    exit 1
fi

# Check for API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable not set"
    echo "End-to-end tests require a valid Claude API key"
    echo
    echo "To run e2e tests:"
    echo "  export ANTHROPIC_API_KEY='your-api-key'"
    echo "  ./tests/run_e2e_tests.sh"
    exit 1
fi

echo "Running end-to-end tests with real Claude API..."
echo "=============================================="
echo "WARNING: These tests will make actual API calls"
echo

# Set test environment
export KS_TEST_MODE=1
export KS_E2E_TEST=1
export TEST_ROOT=$(dirname "$0")

# Run e2e tests
echo "End-to-End Tests:"
echo "-----------------"
if [ -d "$TEST_ROOT/e2e" ] && [ -n "$(find "$TEST_ROOT/e2e" -name "*.bats" 2>/dev/null)" ]; then
    bats "$TEST_ROOT"/e2e/*.bats
else
    echo "No e2e tests found in $TEST_ROOT/e2e/"
    echo "Create *.bats files to test with real Claude API"
fi

echo
echo "End-to-end test suite complete!"