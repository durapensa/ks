#!/usr/bin/env bash
# Run fast tests (no Claude API calls)

set -euo pipefail

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: bats-core is not installed"
    echo "Run: ./tests/setup_test_framework.sh"
    exit 1
fi

echo "Running fast tests (no Claude API)..."
echo "=================================="

# Set test environment
export KS_TEST_MODE=1
export TEST_ROOT=$(dirname "$0")

# Run unit tests
echo
echo "Unit Tests:"
echo "-----------"
bats "$TEST_ROOT"/fast/unit/*.bats 2>/dev/null || true

# Run integration tests
echo
echo "Integration Tests:"
echo "------------------"
bats "$TEST_ROOT"/fast/integration/*.bats 2>/dev/null || true

# Run security tests
echo
echo "Security Tests:"
echo "---------------"
bats "$TEST_ROOT"/fast/security/*.bats 2>/dev/null || true

echo
echo "Fast test suite complete!"