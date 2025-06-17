# Testing Strategy Guide

*Created: 2025-06-17*  
*Status: Testing infrastructure largely complete, this documents current approach*

## Overview

The ks testing infrastructure successfully solves the core challenge of testing AI-powered tools without breaking CI/CD budgets or timeline. This document outlines the current strategy and remaining gaps.

## Test Architecture

### Three-Layer Testing Approach

#### 1. Fast Tests (`tests/fast/`) - 30 seconds
**Purpose**: Core functionality without Claude API  
**Execution**: Every commit, GitHub Actions  
**Coverage**: ~70% of codebase

```bash
tests/fast/
├── unit/
│   ├── test_ks_env_functions.bats     # Environment and utility functions
│   └── test_input_validation.bats     # Parameter validation and sanitization
├── integration/  
│   ├── test_capture_tools.bats        # events, query (no analysis)
│   └── test_process_tools.bats        # rotate-logs, validate-jsonl
└── security/
    └── test_input_validation.bats     # Injection prevention, path security
```

**Key Features**:
- No external dependencies beyond bash/jq
- Predictable, deterministic results
- GitHub Actions friendly (no secrets required)
- Fast feedback loop for development

#### 2. Mocked Tests (`tests/mocked/`) - 60 seconds  
**Purpose**: AI tool functionality with fake Claude responses  
**Execution**: CI/CD and local development  
**Coverage**: ~95% of analysis tool functionality

```bash
tests/mocked/
├── fixtures/
│   ├── claude_responses/              # Pre-generated AI responses
│   │   ├── themes_minimal_dataset.json
│   │   ├── connections_dataset.json
│   │   └── malformed_response.json
│   └── test_events/                   # Predictable event datasets
│       ├── minimal_theme_dataset.jsonl
│       └── connection_dataset.jsonl
├── test_extract_themes_mocked.bats   # Mock ks_claude() function
├── test_find_connections_mocked.bats
└── test_error_scenarios_mocked.bats
```

**Mock Strategy**:
```bash
# Override Claude function in test environment
ks_claude() {
    local prompt="$*"
    case "$prompt" in
        *"extract themes"*) 
            cat tests/mocked/fixtures/claude_responses/themes_minimal.json ;;
        *"find connections"*) 
            cat tests/mocked/fixtures/claude_responses/connections_minimal.json ;;
        *) 
            echo '{"error": "unmocked prompt"}' ;;
    esac
}
```

**Benefits**:
- Consistent, reproducible results
- Tests actual tool logic minus AI variability
- Zero token costs
- Error scenario coverage (timeouts, malformed responses)

#### 3. E2E Tests (`tests/e2e/`) - 5 minutes
**Purpose**: Real Claude API validation  
**Execution**: Local development only (requires ANTHROPIC_API_KEY)  
**Coverage**: End-to-end validation with real AI

```bash
tests/e2e/
├── test_analysis_integration.bats    # Real Claude API calls
├── test_large_dataset_analysis.bats  # Performance validation
└── test_api_error_handling.bats      # Real API failure scenarios
```

**Cost Optimization**:
- Minimal datasets (5-10 events maximum)
- Cached responses to avoid repeated calls
- Optional `--use-cached` flag for development
- Smart test data designed for predictable results

## Current Test Coverage

### ✅ Well Covered
- **Core libraries** - All validation, file processing, utility functions
- **Capture tools** - events, query with comprehensive scenarios
- **Process management** - Background triggers, log rotation, cleanup
- **Security** - Input validation, injection prevention, path security
- **Analysis tools (mocked)** - extract-themes, find-connections with fixtures
- **Error handling** - Malformed data, permissions, API failures

### 🟡 Partially Covered
- **Analysis tools (real)** - Limited E2E validation with actual Claude
- **Background processing** - Mock-based testing, limited real-world scenarios
- **Complex workflows** - Multi-step processes with analysis chains
- **Performance** - Basic benchmarking, no comprehensive load testing

### 🔴 Not Yet Covered
- **Logex conversation testing** - Integration with new dialogue system
- **Knowledge graph distillation** - Limited testing of KG pipeline
- **Cross-tool integration** - Complex workflows spanning multiple tools
- **Resource management** - Memory usage, file handle limits, cleanup

## Execution Strategy

### Development Workflow
```bash
# Quick development cycle (30s)
./tests/run_fast_tests.sh

# Full validation without API costs (90s)  
./tests/run_ci_tests.sh  # fast + mocked

# Complete validation with real Claude (5m)
export ANTHROPIC_API_KEY="your-key"
./tests/run_all_tests.sh

# Specific test debugging
bats tests/mocked/test_extract_themes_mocked.bats -t
```

### CI/CD Integration
```yaml
# GitHub Actions (no secrets required)
jobs:
  test:
    steps:
      - name: Fast Tests
        run: ./tests/run_fast_tests.sh
      - name: Mocked Tests  
        run: ./tests/run_mocked_tests.sh
    # Note: No E2E tests in CI (no API key)
```

## Test Data Strategy

### Minimal, Predictable Datasets
**Design Principle**: Test data should be small enough to understand completely but complex enough to exercise real logic.

```bash
# tests/fixtures/minimal_theme_dataset.jsonl (5 events)
{"ts":"2025-01-01T10:00:00Z","type":"thought","topic":"memory","content":"Human memory is associative"}
{"ts":"2025-01-01T10:01:00Z","type":"thought","topic":"memory","content":"Computer memory is linear"}
{"ts":"2025-01-01T10:02:00Z","type":"connection","topic":"memory-systems","content":"Biological vs digital memory"}
{"ts":"2025-01-01T10:03:00Z","type":"insight","topic":"knowledge","content":"Event sourcing mirrors episodic memory"}
{"ts":"2025-01-01T10:04:00Z","type":"thought","topic":"temporal","content":"Time shapes knowledge formation"}
```

**Expected Analysis Results**:
- Themes: "Memory System Architecture", "Temporal Knowledge Dynamics"
- Connections: biological-digital, memory-knowledge, temporal-knowledge
- Designed for reproducible, testable AI responses

### Fixture Management
```bash
tests/fixtures/
├── claude_responses/          # Pre-generated for consistency
├── test_events/              # Minimal datasets for different scenarios
├── error_scenarios/          # Malformed data, edge cases
└── performance/              # Larger datasets for performance testing
```

## Remaining Work

### High Priority
1. **Logex Integration Testing** - Test conversation harness with mocked Claude
2. **Knowledge Graph Testing** - Distillation pipeline with predictable datasets
3. **Performance Benchmarking** - Systematic testing with various dataset sizes
4. **Error Scenario Expansion** - More comprehensive failure mode coverage

### Medium Priority
5. **Complex Workflow Testing** - Multi-step analysis chains
6. **Resource Management Testing** - Memory, file handles, cleanup validation
7. **Integration Test Expansion** - Cross-tool interaction scenarios
8. **Test Data Generation** - Automated creation of test scenarios

### Low Priority
9. **Load Testing** - High-volume scenario validation
10. **Regression Testing** - Automated detection of behavior changes
11. **Test Documentation** - Comprehensive testing guide for contributors

## Testing Philosophy

### Key Principles
1. **Fast feedback dominates** - Developer productivity requires <30s test cycles
2. **Separate concerns cleanly** - API costs and test speed are different problems
3. **Mock thoughtfully** - Test business logic, not AI response quality
4. **Minimize real API usage** - Expensive and slow, use sparingly for validation
5. **Design for maintainability** - Tests should be easy to understand and update

### Quality Gates
- **All commits**: Fast tests must pass
- **Pull requests**: Fast + mocked tests must pass  
- **Releases**: E2E tests with real Claude validation
- **Nightly**: Performance and load testing (future)

## Integration with Development

### Test-Driven Development Support
```bash
# Create new tool test template
./tests/utils/create_tool_test.sh analyze/new-analysis-tool

# Generates:
# - tests/fast/test_new_analysis_tool.bats (core logic)
# - tests/mocked/test_new_analysis_tool_mocked.bats (with mock fixtures)
# - tests/fixtures/ entries for predictable testing
```

### Continuous Integration Benefits
- **Zero token costs** in CI/CD pipeline
- **Fast execution** enables frequent testing
- **Predictable results** reduce flaky test issues
- **Comprehensive coverage** without expensive API calls

## Success Metrics

### Achieved Goals ✅
- Fast CI/CD execution (<90 seconds total)
- Zero token costs in continuous integration
- 70%+ code coverage without API dependencies
- Predictable, maintainable test results
- Easy local development testing workflow

### Performance Targets
- Fast tests: <30 seconds (✅ achieved)
- Mocked tests: <60 seconds (✅ achieved)  
- E2E tests: <5 minutes (✅ achieved)
- Test development: <10 minutes to add new tool test (✅ achieved)

The testing infrastructure successfully enables confident development of AI-powered tools while maintaining fast, cost-effective validation cycles.