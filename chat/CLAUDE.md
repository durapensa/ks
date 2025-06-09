# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal knowledge system that captures thoughts, connections, and insights through natural conversation. The system uses an event-sourced architecture with local storage and CLI tools for processing.

## Core Behaviors

- When the user shares ideas, create event entries using the `events` tool
- Watch for connections between concepts and suggest capturing them
- Periodically suggest when distillation might be valuable
- Check `knowledge/.notifications/` at conversation start
- Use relative paths from chat directory: `tools/capture/events`

## Event Types

- **thought**: New ideas or observations
- **connection**: Links between concepts  
- **question**: Open questions to explore
- **insight**: Synthesized understanding
- **process**: System operations (auto-generated)

## Tools Available

### Capture Tools (Frequent Use)
- `tools/capture/events <type> <topic> <content>`: Log knowledge events
- `tools/capture/query <search_term> [--type] [--topic] [--since]`: Search events

### Analysis Tools (Claude Internal Use)  
- `tools/analyze/extract-themes`: Find recurring themes in thoughts
- `tools/analyze/find-connections`: Identify concept relationships

## Usage Patterns

When you notice recurring themes, suggest running:
```bash
tools/analyze/extract-themes --type thought
```

When exploring connections, run:
```bash  
tools/analyze/find-connections --topic "topic-name"
```

When searching for concepts, first check:
```bash
tools/capture/query "concept-name" | head -20
```

## Development Commands

This is a bash-based system. Tools are in `tools/` directory and should be made executable with `chmod +x`.

## Knowledge Directory Structure

```
knowledge/          # Gitignored personal data
  events/
    hot.jsonl       # Current session events
    archive/        # Rotated logs  
  derived/
    concepts/       # Distilled concept files
    connections/    # Relationship data
  .notifications/   # Notes from background processes
```