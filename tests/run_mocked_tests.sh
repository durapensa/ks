#!/usr/bin/env bash
# Run tests with mocked Claude API responses

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

echo "Running mocked API tests..."
echo "=========================="

# Set test environment
export KS_TEST_MODE=1
export KS_MOCK_API=1
export TEST_ROOT=$(dirname "$0")

# Run mocked tests
echo
echo "Mocked API Tests:"
echo "-----------------"
if [ -d "$TEST_ROOT/mocked" ] && [ -n "$(find "$TEST_ROOT/mocked" -name "*.bats" 2>/dev/null)" ]; then
    bats "$TEST_ROOT"/mocked/*.bats
else
    echo "No mocked tests found in $TEST_ROOT/mocked/"
    echo "Create *.bats files to test with mocked Claude responses"
fi

echo
echo "Mocked test suite complete!"