# Personal Knowledge System

An event-sourced knowledge system for capturing thoughts, connections, and insights through natural conversation.

## Architecture

- **Local-first**: All data stored on filesystem
- **Event-sourced**: Append-only event log as source of truth
- **Terminal-friendly**: Composable CLI tools
- **LLM-native**: Designed for conversational interaction

## Setup

```bash
# Option 1: Update shell config only
./setup.sh
source ~/.zshrc  # or ~/.bashrc / ~/.bash_profile

# Option 2: Update shell config AND activate immediately
source setup.sh
```

### Dependencies

- `bash` 5.x+ - Modern bash features for performance and safety (required)
- `jq` - JSON processing (required)
- `claude` - Claude CLI (required) 
- `gum` - Beautiful TUI components for dashboard (required for ksd)
- `python3` - For JSONL migration utilities (typically pre-installed)
- GNU coreutils - For consistent date/stat behavior across platforms

**Additional Tools (installed by setup.sh):**
- `util-linux` - Provides getopt and flock for portable argument parsing and file locking
- `sd` - Modern sed replacement for safer text manipulation
- `ripgrep` (rg) - Fast, modern grep for searching
- `pueue` - Process queue management for background tasks
- `watchexec` - File watcher for automated development workflows
- `moreutils` - Unix utilities including `sponge` for safe in-place editing

**Installation:**
- Run `./setup.sh` to check for missing dependencies
- On macOS with Homebrew, it will show what's missing and offer to install automatically
- On Linux, it will provide package manager commands for your distribution
- Configures PATH to prefer GNU tools for consistent cross-platform behavior

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

### Dashboard (Optional)
```bash
ksd                     # Open knowledge system dashboard
```

The dashboard provides:
- Real-time system status and event counts
- Pending analysis notifications
- Quick access to review findings
- Navigation to common tools
- Background process monitoring

Run in a second terminal while using `ks` for a complete overview of your knowledge system activity.

## Directory Structure

```
chat/                   # Conversation context
  CLAUDE.md             # Knowledge system instructions
  knowledge/            # Symlink to ../knowledge
  tools/                # Symlink to ../tools
knowledge/              # Personal data (gitignored)
  events/hot.jsonl      # Current event stream
  derived/              # Processed knowledge
tools/                  # Processing utilities (category-based)
  capture/              # Event capture and query
  analyze/              # AI-powered pattern extraction
  introspect/           # Human reflection and review
  plumbing/             # System infrastructure
  utils/                # Specialized utilities
lib/                    # Core library modules
  categories.sh         # Category-based argument definitions
  validation.sh         # Category-specific validation
tools/lib/              # Tool-specific library modules
  analysis.sh           # Business logic for analysis tools
```

## Tools

All tools use category-based argument parsing for consistent interfaces and behavior.

### Capture (CAPTURE_INPUT/CAPTURE_SEARCH categories)
- `tools/capture/events` - Log knowledge events (JSONL format)
  - Usage: `events TYPE TOPIC [CONTENT]`
  - Supports stdin input for piped content
- `tools/capture/query` - Search events across hot log and archives
  - Standard options: `--days`, `--since`, `--type`, `--topic`, `--limit`, `--reverse`, `--count`

### Analysis (ANALYZE category)  
- `tools/analyze/extract-themes` - Find recurring themes using AI analysis
- `tools/analyze/find-connections` - Discover non-obvious connections between events
- `tools/analyze/identify-recurring-thought-patterns` - Pattern analysis for thought events
- `tools/analyze/curate-duplicate-knowledge` - Prevent knowledge graph pollution
  - Standard options: `--days`, `--since`, `--type`, `--topic`, `--format`, `--verbose`
  - Custom options: `--content`, `--threshold`, `--window`, `--sources`

### Introspection (INTROSPECT category)
- `tools/introspect/review-findings` - Interactive review of background analysis results
  - Options: `--list`, `--batch-size`, `--detailed`, `--interactive`, `--confidence-threshold`

### System Infrastructure (PLUMBING category)
- `tools/plumbing/check-event-triggers` - Monitor event thresholds and spawn analyses
- `tools/plumbing/monitor-background-processes` - Manage background analysis processes  
- `tools/plumbing/rotate-logs` - Rotate event logs from hot to archive
  - Standard options: `--verbose`, `--dry-run`, `--force`
  - Custom options: `--max-size`, `--max-age`, `--max-events`

### Utilities (UTILS category)
- `tools/utils/validate-jsonl` - Validate JSONL file format
- `tools/utils/generate-argparse` - Generate category-based argument parsers

## Category System

The knowledge system uses a category-based argument parsing system for consistency across all tools:

**Categories and Standard Options:**
- **ANALYZE**: `--days`, `--since`, `--type`, `--topic`, `--format`, `--verbose`
- **CAPTURE_INPUT**: Custom positional arguments (TYPE TOPIC [CONTENT])
- **CAPTURE_SEARCH**: `--days`, `--since`, `--type`, `--topic`, `--limit`, `--reverse`, `--count`  
- **PLUMBING**: `--verbose`, `--dry-run`, `--force`, `--status`, `--active`, `--completed`, `--failed`, `--cleanup`
- **INTROSPECT**: `--list`, `--batch-size`, `--detailed`, `--interactive`, `--confidence-threshold`
- **UTILS**: Custom argument patterns per tool

**Code Generation:**
```bash
# Generate argument parser for a new tool
tools/utils/generate-argparse ANALYZE --tool-name my-analysis --description "My analysis tool"
```

This system eliminates code duplication and ensures consistent interfaces across all tools.


## Event Format

Events are stored in JSONL (JSON Lines) format - one JSON object per line:

```json
{"ts":"2025-06-09T16:06:01Z","type":"thought","topic":"memory","content":"Human memory is associative...","metadata":{}}
```

Event types: `thought`, `connection`, `question`, `insight`, `process`

## Background Analysis

The system can automatically run analysis in the background to surface themes and insights.

### Event-Driven Analysis

Background analyses are automatically triggered based on event count thresholds:

```bash
# Configuration (environment variables)
export KS_EVENT_THRESHOLD_THEMES=10        # Trigger theme analysis (default: 10)
export KS_EVENT_THRESHOLD_CONNECTIONS=20   # Trigger connections (default: 20)
export KS_EVENT_THRESHOLD_PATTERNS=30      # Trigger patterns (default: 30)
```

How it works:
1. Each event capture checks if thresholds are met
2. Analyses spawn automatically in background
3. You're notified when findings are ready for review
4. Review findings in a separate terminal

### Reviewing Analysis Findings

When notified of pending analyses:

```bash
# Run in a separate terminal
tools/workflow/review-findings

# List pending analyses without reviewing
tools/workflow/review-findings --list
```

The review process:
- Each finding is shown individually
- Approve (y) or reject (n) each finding
- Approved findings become new insight events
- Queue is cleared after review

### Monitoring Background Processing

```bash
# Check analysis queue
cat knowledge/.background/analysis_queue.json | jq .

# Monitor background processes
tools/plumbing/monitor-background-processes --status

# Check trigger state
cat knowledge/.background/.event_trigger_state

# View logs
tail -f knowledge/.background/analysis.log
```

### Manual Trigger Testing

```bash
# Force trigger check (verbose mode)
tools/plumbing/check-event-triggers verbose

# Reset trigger counts if needed
echo '{"last_count": 0, "last_theme_trigger": 0, "last_connection_trigger": 0, "last_pattern_trigger": 0, "last_check": "2025-01-01T00:00:00Z"}' > knowledge/.background/.event_trigger_state
```

The system prevents duplicate analyses by blocking new runs while findings await review.

## Architecture Benefits

- **Context separation**: Conversation vs analysis modes
- **Clean tool interfaces**: Explicit prompts via `claude --print`
- **Symlinked access**: Tools work from conversation context
- **Extensible**: Easy to add new analysis capabilities