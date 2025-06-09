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

- **Testing Commands**: Be extremely careful when running bash commands that modify the knowledge base (especially the hot.jsonl file). Always create backups before testing log rotation or file manipulation. The event log is append-only by design - corrupting it breaks the entire system.
- **Archive Testing**: When testing archive functionality, use proper JSONL format - each line must be a complete JSON object. Simple head/tail commands can break JSON structure.