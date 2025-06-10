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
- `python3` - For JSONL migration utilities (typically pre-installed)
- `flock` - File locking for log rotation (optional but recommended)
- GNU coreutils - For consistent date/stat behavior across platforms

**Automatic Installation (macOS):**
- On macOS with Homebrew, `setup.sh` will detect missing dependencies and offer to install them automatically
- Installs GNU coreutils for cross-platform compatibility (eliminates date/stat command differences)
- Configures PATH to prefer GNU tools, ensuring consistent behavior across platforms

**Manual Installation:**
- macOS: `brew install bash jq coreutils util-linux` (then install Claude CLI separately)
- Linux: Use your distribution's package manager (ensure bash 5.x+)

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
- `tools/capture/events` - Log knowledge events (JSONL format)
- `tools/capture/query` - Search events across hot log and archives

### Analysis  
- `tools/analyze/extract-themes` - Find recurring themes
  - Supports `--format [text|json|markdown]` output
  - Use `--days N` to limit time range
  - Use `--type TYPE` to filter by event type
- `tools/analyze/find-connections` - Identify concept relationships
  - Supports `--format [text|json|markdown]` output
  - Use `--days N` to limit time range
  - Use `--topic TOPIC` to filter by topic

### Process
- `tools/process/rotate-logs` - Archive old events
  - `--max-size BYTES` - Rotate when size exceeded
  - `--max-age HOURS` - Rotate when age exceeded
  - `--max-events COUNT` - Rotate when count exceeded
  - `--force` - Force immediate rotation

### Utilities
- `tools/utils/validate-jsonl` - Validate JSONL file format
- `tools/utils/migrate-to-jsonl.py` - Convert multi-line JSON to JSONL

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