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

## Development Workflow

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

**NEVER use emojis or pictographic symbols** in any documentation, code comments, or GitHub issues. Use clear, professional text-only communication.