# Knowledge System Test Suite

Comprehensive test suite with smart Claude API separation for cost-effective CI/CD.

## Quick Start

```bash
# Install test framework
./tests/setup_test_framework.sh

# Run tests
./tests/run_fast_tests.sh      # No API calls (CI-friendly)
./tests/run_mocked_tests.sh    # Mocked Claude responses
./tests/run_e2e_tests.sh       # Real Claude API (requires key)
./tests/run_ci_tests.sh        # Fast + mocked (for GitHub Actions)
```

## Test Architecture

### 1. Fast Tests (`tests/fast/`)
- **No Claude API calls**
- **Execution time**: <30 seconds
- **Coverage**: ~70% of non-AI functionality
- **Categories**: unit, integration, security

### 2. Mocked Tests (`tests/mocked/`)
- **Fake Claude responses** using fixtures
- **Execution time**: <60 seconds  
- **Coverage**: 95% of analysis tool functionality
- **Predictable results** for CI/CD

### 3. E2E Tests (`tests/e2e/`)
- **Real Claude API** calls
- **Local only** (requires ANTHROPIC_API_KEY)
- **Minimal datasets** to reduce costs
- **Cached responses** for development

## Test Data Strategy

### Minimal Datasets
- 5-10 events maximum per test
- Predictable content for consistent results
- Located in `tests/mocked/fixtures/test_events/`

### Mock Responses
- Pre-generated Claude API responses
- JSON format in `tests/mocked/fixtures/claude_responses/`
- Cover success and error scenarios

## Writing Tests

### Unit Test Example
```bash
@test "ks_validate_days accepts valid input" {
    run ks_validate_days 7
    [ "$status" -eq 0 ]
}
```

### Mocked Test Example
```bash
@test "extract-themes with mocked Claude" {
    # Override ks_claude function
    ks_claude() {
        cat "$BATS_TEST_DIRNAME/fixtures/themes_response.json"
    }
    
    run extract-themes --days 1 --format json
    [ "$status" -eq 0 ]
}
```

## CI/CD Integration

GitHub Actions workflow runs fast and mocked tests on every push:
- No API keys required
- ~90 second total execution
- Cross-platform (Ubuntu, macOS)

## Cost Management

- **CI/CD**: $0 (no real API calls)
- **Local E2E**: <$0.50 per full run
- **Development**: Use cached responses

## Current Status

- ✅ Unit tests: 9/9 passing
- 🔧 Integration tests: Need tool updates
- ✅ Test framework: Fully operational
- ✅ GitHub Actions: Configured