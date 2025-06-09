# Personal Knowledge System

An event-sourced knowledge system for capturing thoughts, connections, and insights through natural conversation.

## Architecture

- **Local-first**: All data stored on filesystem
- **Event-sourced**: Append-only event log as source of truth
- **Terminal-friendly**: Composable CLI tools
- **LLM-native**: Designed for conversational interaction

## Setup

```bash
# Run setup (adds 'ks' command and configures environment)
./setup.sh
source ~/.zshrc  # or ~/.bashrc / ~/.bash_profile
```

## Configuration

```bash
# Set Claude model for analysis tools (default: sonnet)
export KS_MODEL=opus    # Use Opus for deeper analysis
export KS_MODEL=sonnet  # Use Sonnet (default, faster)
```

## Usage

### Conversation Mode
```bash
ks                      # Enter knowledge capture conversation
ks --continue           # Continue previous conversation
```

During conversation, Claude will automatically:
- Capture thoughts and insights as events
- Query past knowledge when relevant
- Analyze patterns and connections
- Build your knowledge graph over time

## Directory Structure

```
chat/                   # Conversation context
  CLAUDE.md             # Knowledge system instructions
  knowledge/            # Symlink to ../knowledge
  tools/                # Symlink to ../tools
knowledge/              # Personal data (gitignored)
  events/hot.jsonl      # Current event stream
  derived/              # Processed knowledge
tools/                  # Processing utilities
  capture/              # Event capture and query
  analyze/              # Pattern extraction
  process/              # Batch operations
  monitor/              # Real-time analysis
```

## Tools

### Capture
- `tools/capture/events` - Log knowledge events
- `tools/capture/query` - Search events and knowledge

### Analysis  
- `tools/analyze/extract-themes` - Find recurring themes
- `tools/analyze/find-connections` - Identify concept relationships

## Architecture Benefits

- **Context separation**: Conversation vs analysis modes
- **Clean tool interfaces**: Explicit prompts via `claude --print`
- **Symlinked access**: Tools work from conversation context
- **Extensible**: Easy to add new analysis capabilities