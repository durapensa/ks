#!/usr/bin/env bash
# Run tests suitable for CI/CD (fast + mocked, no real API calls)

set -euo pipefail

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: bats-core is not installed"
    echo "Run: ./tests/setup_test_framework.sh"
    exit 1
fi

echo "Running CI test suite (fast + mocked)..."
echo "======================================="
echo "These tests do not require API keys"
echo

# Set test environment
export KS_TEST_MODE=1
export KS_CI_TEST=1
export TEST_ROOT=$(dirname "$0")

# Track test results
FAST_EXIT=0
MOCKED_EXIT=0

# Run fast tests
echo "=== FAST TESTS ==="
"$TEST_ROOT/run_fast_tests.sh" || FAST_EXIT=$?

echo
echo "=== MOCKED TESTS ==="
"$TEST_ROOT/run_mocked_tests.sh" || MOCKED_EXIT=$?

# Summary
echo
echo "======================================="
echo "CI Test Suite Summary:"
echo "  Fast tests:   $([ $FAST_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"
echo "  Mocked tests: $([ $MOCKED_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"

# Exit with error if any test suite failed
if [ $FAST_EXIT -ne 0 ] || [ $MOCKED_EXIT -ne 0 ]; then
    echo
    echo "CI test suite FAILED"
    exit 1
fi

echo
echo "CI test suite PASSED!"