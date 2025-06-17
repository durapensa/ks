# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal knowledge system with event-sourced architecture for capturing thoughts and insights through natural conversation, automated AI analysis, and human curation.

## Quick Start

```bash
# Initial setup
./setup.sh                           # Configure environment and dependencies

# Daily usage
ks                                   # Enter conversational capture mode
ksd                                  # Open dashboard in second terminal (optional)

# Development workflow
gh issue list --label "priority: high"  # Check current priorities
./tests/run_fast_tests.sh              # Run unit tests
docs/implementation-status.md           # Current system status
```

## Dynamic Help System

**When** you need tool usage information:
- **Then** use `ks --claudehelp` for core tools and usage patterns
- **Then** use `ks --allhelp` for comprehensive tool documentation
- **Then** use `<toolname> --help` for specific tool details
- **Then** refer to these dynamic sources rather than outdated documentation

**When** exploring available tools:
- **Then** run `ks` without arguments to see all discovered tools by category
- **Then** check `tools/` directories for tool organization by function
- **Then** use tab completion after `ks ` to see available subcommands

## Core Workflows

### Knowledge Capture Workflow

**When** the user wants to capture knowledge:
- **Then** start `ks` for interactive conversation mode
- **Then** let background analysis run automatically after event thresholds
- **Then** use `ksd` for real-time monitoring of system activity
- **Then** review findings via `ks review-findings` when notified

### Development Workflow

**When** implementing new features or fixes:
- **Then** check `docs/implementation-status.md` for current system reality
- **Then** verify related GitHub issues with `gh issue view <number>`
- **Then** run `./tests/run_fast_tests.sh` before making changes
- **Then** follow tool development conventions outlined below

**When** completing development work:
- **Then** run tests to verify no regressions: `./tests/run_fast_tests.sh`
- **Then** commit changes with descriptive messages referencing issue numbers
- **Then** push to remote repository to share progress
- **Then** update issue status and close when complete

## System Architecture

**Current Implementation Status**: The system is much more mature than GitHub issues suggest. Key components are functional:

- **Testing Infrastructure**: Fast/mocked/e2e test separation with comprehensive coverage
- **Knowledge Graph**: SQLite-based concept distillation with weight attribution
- **Conversation Harness**: Automated AI-to-AI dialogue system (logex)
- **Background Analysis**: Automatic theme/connection/pattern extraction
- **Dashboard System**: Real-time TUI monitoring with Go-based ksd

**When** assessing system capabilities:
- **Then** check `docs/implementation-status.md` for accurate status
- **Then** verify functionality exists before planning implementation
- **Then** focus on enhancement rather than greenfield development

## Tool Development Conventions

### Standard Tool Structure

**When** creating any new ks tool:
- **Then** use header format: `#!/usr/bin/env bash` + blank line + `# tool-name - description`
- **Then** include `set -euo pipefail` for robust error handling
- **Then** source libraries in order: `.ks-env`, `core.sh`, `error.sh`, `usage.sh`, `argparse.sh`
- **Then** source category-specific libraries from `tools/lib/` as needed

### Argument Parsing Requirements

**When** implementing argument parsing:
- **Then** use `ks_parse_category_args "CATEGORY" -- "$@"` instead of manual getopt
- **Then** choose appropriate category: ANALYZE, CAPTURE_INPUT, CAPTURE_SEARCH, PLUMBING, INTROSPECT, LOGEX, UTILS
- **Then** implement usage() with `ks_generate_usage` following standard pattern
- **Then** use `REMAINING_ARGS` array for positional arguments after parsing

**When** needing custom arguments not in existing categories:
- **Then** first check if UTILS category fits for specialized tools
- **Then** consider extending existing category if options are broadly applicable
- **Then** use `ks_parse_custom_args` only when truly necessary
- **Then** document rationale for deviating from standard categories

### Error Handling Standards

**When** implementing error conditions:
- **Then** use `ks_exit_usage` for argument validation errors
- **Then** use `ks_exit_error` for runtime failures
- **Then** use `ks_exit_validation` for input validation errors
- **Then** avoid manual `echo ... >&2; exit 1` patterns

### Integration Testing

**When** completing tool development:
- **Then** run `./tests/run_fast_tests.sh` to verify no regressions
- **Then** test `--help` functionality manually
- **Then** verify error handling with invalid arguments
- **Then** ensure tool integrates with `ks` command discovery

## Logex Conversation System

**When** working with automated conversations:
- **Then** understand that logex provides YAML-based conversation orchestration
- **Then** use `tools/logex/configure` to create conversation setups
- **Then** run conversations via `tools/logex/orchestrate-worker`
- **Then** capture conversation events automatically into knowledge system

**When** designing conversation experiments:
- **Then** refer to `docs/kg-implementation-status.md` for experiment recommendations
- **Then** use logex to test knowledge graph enhancement priorities
- **Then** focus on data-driven development based on experimental results

## Library System

**When** building tools that need shared functionality:
- **Then** use core libraries from `lib/` for essential utilities
- **Then** use tool-specific libraries from `tools/lib/` for specialized functions
- **Then** load only needed libraries to minimize script overhead
- **Then** follow modular loading patterns established in existing tools

**Key Libraries**:
- `lib/core.sh` - Directory creation, timestamps, validation
- `lib/events.sh` - Event validation and counting
- `tools/lib/claude.sh` - AI integration and analysis formatting
- `tools/lib/queue.sh` - Background analysis queue management

## Testing Strategy

**When** adding new functionality:
- **Then** add fast tests (no Claude API) for core logic
- **Then** add mocked tests with predictable AI responses
- **Then** consider e2e tests only for critical integration points
- **Then** follow test data patterns in `tests/fixtures/`

**When** running tests during development:
- **Then** use `./tests/run_fast_tests.sh` for quick feedback (30 seconds)
- **Then** use `./tests/run_mocked_tests.sh` for analysis tool validation
- **Then** use `./tests/run_e2e_tests.sh` only for final validation with real Claude

## Communication Guidelines

**When** creating documentation or commit messages:
- **Then** use clear, professional text without emojis or pictographic symbols
- **Then** avoid excessive capitalization or hyperbolic language
- **Then** describe implementations as "functional" or "working" rather than "complete"
- **Then** let results demonstrate value rather than declaring success

**When** updating GitHub issues:
- **Then** provide concrete status updates with specific accomplishments
- **Then** reference actual implementation details and file locations
- **Then** close issues only when functionality is tested and integrated

## Current Development Context

**Active Systems**: Testing infrastructure, knowledge graph, conversation harness, dashboard are functional and ready for enhancement rather than initial implementation.

**Priority Focus**: Use logex conversation experiments to determine which system enhancements provide the most value, rather than theoretical feature planning.

**Development Approach**: Build on existing solid foundation with data-driven priorities based on experimental results and actual usage patterns.

**When** planning new work:
- **Then** check `docs/implementation-status.md` for current reality
- **Then** prioritize enhancements over greenfield development
- **Then** design experiments to validate enhancement value
- **Then** focus on user experience improvements and system polish

This guidance reflects the mature state of the ks system and emphasizes enhancement and experimentation over initial implementation.