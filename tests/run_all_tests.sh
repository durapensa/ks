#!/usr/bin/env bash
# Run all test suites (fast, mocked, e2e, performance)

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

echo "Running complete test suite..."
echo "============================="

# Set test environment
export KS_TEST_MODE=1
export TEST_ROOT=$(dirname "$0")

# Track test results
FAST_EXIT=0
MOCKED_EXIT=0
E2E_EXIT=0
PERF_EXIT=0

# Run fast tests
echo
echo "=== FAST TESTS ==="
"$TEST_ROOT/run_fast_tests.sh" || FAST_EXIT=$?

# Run mocked tests
echo
echo "=== MOCKED TESTS ==="
"$TEST_ROOT/run_mocked_tests.sh" || MOCKED_EXIT=$?

# Run e2e tests if API key is available
echo
echo "=== END-TO-END TESTS ==="
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    "$TEST_ROOT/run_e2e_tests.sh" || E2E_EXIT=$?
else
    echo "Skipping e2e tests (no ANTHROPIC_API_KEY)"
    echo "To run e2e tests: export ANTHROPIC_API_KEY='your-api-key'"
fi

# Run performance tests
echo
echo "=== PERFORMANCE TESTS ==="
if [ -d "$TEST_ROOT/performance" ] && [ -n "$($KS_FIND "$TEST_ROOT/performance" -name "*.bats" 2>/dev/null)" ]; then
    echo "Performance Tests:"
    echo "------------------"
    bats "$TEST_ROOT"/performance/*.bats || PERF_EXIT=$?
else
    echo "No performance tests found in $TEST_ROOT/performance/"
fi

# Summary
echo
echo "============================="
echo "Complete Test Suite Summary:"
echo "  Fast tests:        $([ $FAST_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"
echo "  Mocked tests:      $([ $MOCKED_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "  E2E tests:         $([ $E2E_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"
else
    echo "  E2E tests:         SKIPPED (no API key)"
fi
echo "  Performance tests: $([ $PERF_EXIT -eq 0 ] && echo "PASSED" || echo "FAILED")"

# Exit with error if any test suite failed
TOTAL_EXIT=$((FAST_EXIT + MOCKED_EXIT + E2E_EXIT + PERF_EXIT))
if [ $TOTAL_EXIT -ne 0 ]; then
    echo
    echo "Test suite FAILED"
    exit 1
fi

echo
echo "All tests PASSED!"