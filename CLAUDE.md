# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal knowledge system with event-sourced architecture for capturing thoughts and insights.

## Quick Start

```bash
# Initial setup
./setup.sh                           # Configure environment and dependencies

# Daily usage
ks                                   # Enter conversational capture mode
ksd                                  # Open dashboard in second terminal (optional)
tools/capture/query "search term"    # Search existing knowledge

# Development workflow
gh issue list --label "priority: high"  # Check current priorities
./tests/run_fast_tests.sh              # Run unit tests
tools/plumbing/monitor-background-processes --status  # Check system health
```

## Core Usage Patterns

- **`ks`** command - Enter conversational knowledge capture mode (configured via setup.sh)
- **`ksd`** command - Dashboard for monitoring system status and pending reviews (optional)
- **`tools/`** - Internal processing tools for knowledge analysis
- **Background Analysis** - Automatic theme/connection extraction after event thresholds
- **Review Workflow** - `tools/workflow/review-findings` for approving insights

## Architecture

```
chat/           # Conversation context with symlinks
tools/          # Categorized processing tools
knowledge/      # Personal data (gitignored)
lib/            # Core library modules
tools/lib/      # Tool-specific library modules
.ks-env         # Centralized environment configuration
```

## Configuration

- `KS_MODEL` - Claude model for analysis tools (default: sonnet)
- `KS_ROOT` - Project root directory (set by .ks-env)
- **Event Thresholds** - Background analysis triggers (default: 10 events for themes, 20 for connections)
- **Testing** - Use `./tests/run_fast_tests.sh` for development iteration

## Important Notes

- **JSONL Format**: The knowledge event log uses JSONL (JSON Lines) format where each line is a complete, valid JSON object. This format is grep-friendly and supports streaming operations.
- **Data Integrity**: The event log is append-only by design. Always create backups before testing log rotation or file manipulation.
- **Format Validation**: Use `tools/utils/validate-jsonl` to check file integrity.
- **Migration Tool**: If you encounter multi-line JSON format, use `tools/utils/migrate-to-jsonl.py` to convert to proper JSONL format.
- **Cross-Platform Compatibility**: On macOS, `setup.sh` automatically configures GNU coreutils for consistent date/stat behavior across platforms.
## Library System

Scripts use modular libraries to load only needed functions:

### Core Libraries (`lib/`)
- **core.sh** - Essential utilities: directory creation, timestamps, input validation
- **events.sh** - Event validation and counting
- **files.sh** - JSONL file collection and ordering
- **categories.sh** - Category-based option definitions for consistent argument parsing
- **validation.sh** - Category-specific validation functions

### Tools Libraries (`tools/lib/`)
- **claude.sh** - Claude AI integration and analysis formatting
- **queue.sh** - Background analysis queue management
- **process.sh** - Background process tracking and locking
- **analysis.sh** - Business logic for analysis tools (extracted from old argparse.sh)

### Argument Parsing System

All tools use category-based argument parsing for consistency:

**Categories:**
- **ANALYZE** - AI analysis tools (days, since, type, topic, format, verbose)
- **CAPTURE_INPUT** - Event capture tools (custom positional arguments)
- **CAPTURE_SEARCH** - Knowledge search tools (days, search, type, topic, limit, reverse, count)
- **PLUMBING** - System infrastructure tools (verbose, dry-run, force, status, active, completed, failed, cleanup)
- **INTROSPECT** - Human reflection tools (list, batch-size, detailed, interactive, confidence-threshold)
- **UTILS** - Specialized tools (custom argument patterns)

**Usage Example:**
```bash
#!/usr/bin/env bash
source "${0%/*}/../../.ks-env"
source "$KS_ROOT/lib/core.sh"
source "$KS_ROOT/lib/validation.sh"
source "$KS_ROOT/tools/lib/analysis.sh"

# Generated argument parsing (ANALYZE category)
usage() { ... }
# Build getopt options
LONG_OPTS="help,days:,since:,type:,format:,verbose"
# Parse and validate
...
```

**Code Generation:**
Use `tools/utils/generate-argparse CATEGORY --tool-name name --description "desc"` to generate consistent parsers.

Scripts load ~50-200 lines instead of the old 420-line monolithic library, with generated argument parsing replacing complex declarative systems.

## ks Tool Development Conventions

**Critical**: All ks tools must follow established conventions for consistency, maintainability, and integration. The logex tools serve as exemplary implementations after major convention alignment (2025-06-16).

### Standard Tool Structure Pattern

**When** creating any new ks tool:
- **Then** use the standard header format: `#!/usr/bin/env bash` + blank line + `# tool-name - description`
- **Then** include `set -euo pipefail` for robust error handling
- **Then** add the standard library sourcing comment: `# Source configuration and modular libraries`
- **Then** source libraries in this order: `.ks-env`, `core.sh`, `error.sh`, `usage.sh`, `argparse.sh`
- **Then** source category-specific libraries from `tools/lib/` as needed

### Argument Parsing Requirements

**When** implementing argument parsing for any tool:
- **Then** use `ks_parse_category_args "CATEGORY" -- "$@"` instead of manual getopt parsing
- **Then** choose the appropriate category: ANALYZE, CAPTURE_INPUT, CAPTURE_SEARCH, PLUMBING, INTROSPECT, LOGEX, or UTILS
- **Then** implement usage() with `ks_generate_usage` following the standard pattern:
  ```bash
  usage() {
      declare -a arguments=(...)
      declare -a examples=(...)
      ks_generate_usage \
          "Tool description" \
          "tool-name" \
          "[options] ARGS" \
          "CATEGORY" \
          arguments \
          examples
  }
  ```
- **Then** use `REMAINING_ARGS` array for positional arguments after parsing

### Error Handling Standards

**When** implementing error conditions in tools:
- **Then** use `ks_exit_usage` for argument validation errors
- **Then** use `ks_exit_error` for runtime failures
- **Then** use `ks_exit_validation` for input validation errors
- **Then** avoid manual `echo ... >&2; exit 1` patterns

### Convention Validation Workflow

**When** modifying existing tools or reviewing tool implementations:
- **Then** verify usage() function uses `ks_generate_usage` (not `cat << EOF`)
- **Then** confirm argument parsing uses category-based system (not manual `while/case` loops)
- **Then** check error handling uses standard `ks_exit_*` functions
- **Then** validate header comments follow `# tool-name - description` format
- **Then** ensure library sourcing includes the standard comment and order

**When** creating tools with custom options not in existing categories:
- **Then** first check if the tool fits UTILS category for specialized tools
- **Then** consider extending an existing category if the options are broadly applicable
- **Then** use `ks_parse_custom_args` if truly custom options are needed
- **Then** document the rationale for deviating from standard categories

### Integration Testing

**When** completing tool development or modification:
- **Then** run `./tests/run_fast_tests.sh` to verify no regressions
- **Then** test `--help` functionality manually
- **Then** verify error handling with invalid arguments
- **Then** ensure the tool integrates correctly with `ks` command discovery

### Reference Implementations

**Best Practice Examples**:
- **Category-based tools**: `tools/analyze/extract-themes`, `tools/capture/query`
- **LOGEX tools**: `tools/logex/configure`, `tools/logex/claude-instance` (post-2025-06-16 refactoring)
- **Library usage**: `tools/capture/events` for comprehensive library integration

**Anti-patterns to Avoid**:
- Manual getopt parsing with 40+ line `while/case` constructs
- Custom `parse_arguments()` functions duplicating library functionality
- `cat << EOF` usage functions instead of `ks_generate_usage`
- Direct `exit 1` instead of `ks_exit_*` functions

## Development Priorities

Active work is tracked through GitHub milestones:
- **Testing Infrastructure** - Conversation harness and automated testing (start here)
- **Knowledge Graph Implementation** - SQLite-based distilled knowledge storage
- **Dashboard & UI Improvements** - Enhanced interfaces and user experience

Use `gh issue list --label "priority: high"` to see immediate priorities.

## Development Workflow

**When** the user agrees to implement a feature or fix:
- **Then** check the relevant GitHub issue for context and requirements
- **Then** create a clear implementation plan with specific steps
- **Then** reference the issue number in commits for traceability

**When** you successfully complete an issue or make significant improvements:
- **Then** commit your changes with a descriptive message referencing the issue number
- **Then** push to the remote repository to share your progress
- **Then** close the issue with `gh issue close <number>` after documenting the resolution

**When** you finish a work session with tested changes:
- **Then** commit and push your work to prevent data loss
- **Then** ensure the commit message explains what was changed and why

**When** ending any development session:
- **Then** ALWAYS stage, commit, and push all tested changes before session termination
- **Then** verify clean working directory with `git status` to prevent work loss
- **Then** update issue comments if significant progress was made

## Active Development

Track work via GitHub:
- `gh issue list --milestone <name>` - View issues by milestone
- `gh issue list --label "priority: high"` - See high-priority items
- `gh issue view <number>` - Get detailed issue information

## Testing Strategy

- **Fast Tests** - `./tests/run_fast_tests.sh` (unit tests, no Claude API)
- **Mocked Tests** - `./tests/run_mocked_tests.sh` (analysis tools with fixtures)  
- **CI Tests** - `./tests/run_ci_tests.sh` (GitHub Actions compatible)
- **E2E Tests** - `./tests/run_e2e_tests.sh` (real Claude API, local only)

## Documentation Hygiene

**Critical**: Keep documentation focused and avoid redundancy:
- `CLAUDE.md` provides project overview and workflow guidance  
- GitHub issues and milestones track priorities and progress
- Git history records what was completed
- Issue comments capture implementation details and decisions

## Communication Style

**Never use emojis or pictographic symbols** in any documentation, code comments, or GitHub issues. Use clear, professional text-only communication.

**Tone Guidelines**:
- Avoid excessive capitalization (no ALLCAPS for emphasis)
- Use measured, professional language
- Don't declare features "complete" until tested over time
- Prefer understated descriptions over hyperbole
- Let results speak for themselves

## Development Language Guidelines

**Research Software Context**: This is ongoing research software that will evolve continuously. NEVER describe implementations as:
- "production-ready" 
- "complete"
- "finished"
- "fully implemented"

**Instead use language that reflects iterative development**:
- "functional and tested"
- "implemented with room for enhancement"
- "working implementation, ready for further development"
- "foundational version complete"

This software will be developed and refined indefinitely as part of ongoing research.