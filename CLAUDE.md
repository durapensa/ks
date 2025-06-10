# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal knowledge system with event-sourced architecture for capturing thoughts and insights.

## Usage

- **`ks`** command - Enter conversational knowledge capture mode (configured via setup.sh)
- **`tools/`** - Internal processing tools for knowledge analysis

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

### Tools Libraries (`tools/lib/`)
- **claude.sh** - Claude AI integration and analysis formatting
- **queue.sh** - Background analysis queue management
- **process.sh** - Background process tracking and locking

### Usage Example
```bash
#!/usr/bin/env bash
source "${0%/*}/../../.ks-env"
source "$KS_ROOT/lib/core.sh"         # Essential utilities
source "$KS_ROOT/lib/files.sh"        # If processing files  
source "$KS_ROOT/tools/lib/claude.sh" # If using Claude
```

Scripts load ~50-200 lines instead of the old 420-line monolithic library.

## Development Workflow

**When** the user agrees to implement a feature or fix:
- **Then** IMMEDIATELY document your complete implementation plan in `DEVELOPMENT_STATUS.md`
- **Then** include specific steps, files to modify, and expected outcomes
- **Then** this plan serves as both documentation and a roadmap for the work

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
- **Then** update `DEVELOPMENT_STATUS.md` if significant progress was made

## Current Development Context

**IMPORTANT**: Check `DEVELOPMENT_STATUS.md` for current priorities, technical debt, and next steps.

## Active Development

Track development with `gh issue list`. Use `gh issue view <number>` for details.

## Documentation Hygiene

**Critical**: Keep development context current and avoid redundancy:
- `DEVELOPMENT_STATUS.md` tracks immediate priorities and technical debt
- `CLAUDE.md` provides project overview and workflow guidance  
- Git history tracks what was completed (no need to duplicate in docs)
- GitHub issues track specific feature requests and bugs

Update `DEVELOPMENT_STATUS.md` after significant changes to maintain session continuity.

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