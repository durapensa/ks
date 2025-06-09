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

## Active Development

Track development with `gh issue list`. Current priorities:
- Issue #1: Test harness for automated conversation testing
- Issue #2: Log rotation tool for archive management
- Issue #3: Background analysis scheduler
- Issue #4: Archive search functionality fixes
- Issue #5: Notification system implementation
- Issue #6: Output formatting for analysis tools

Use `gh issue view <number>` for details.