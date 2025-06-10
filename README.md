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

- `jq` - JSON processing (required)
- `claude` - Claude CLI (required) 
- `python3` - For JSONL migration utilities (typically pre-installed)
- `flock` - File locking for log rotation (optional but recommended)
- Standard Unix tools: `bash`, `grep`, `find`, `date`

**Automatic Installation (macOS):**
- On macOS with Homebrew, `setup.sh` will detect missing dependencies and offer to install them automatically
- Installs GNU coreutils for cross-platform compatibility (eliminates date/stat command differences)
- Configures PATH to prefer GNU tools, ensuring consistent behavior across platforms

**Manual Installation:**
- macOS: `brew install jq coreutils util-linux` (then install Claude CLI separately)
- Linux: Use your distribution's package manager

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

### Daemon Mode

Run continuously in a terminal or screen session:

```bash
tools/plumbing/schedule-analysis-cycles --daemon
```

This will:
- Check every hour for analysis needs
- Respect event thresholds and budget limits
- Write PID to `knowledge/.background/daemon.pid`
- Log to `knowledge/.background/analysis.log`

### macOS launchd (Recommended)

Install as a system service that starts on login:

```bash
tools/plumbing/schedule-analysis-cycles --install-launchd
```

Manage the service:
```bash
# Check status
launchctl list | grep com.ks.background-analysis

# Stop/start service
launchctl unload ~/Library/LaunchAgents/com.ks.background-analysis.plist
launchctl load ~/Library/LaunchAgents/com.ks.background-analysis.plist
```

### Cron (Unix/Linux)

Add to your crontab:
```bash
# Run every hour
0 * * * * /path/to/ks/tools/plumbing/schedule-analysis-cycles --run
```

### Background Analysis Configuration

```bash
# Daily budget in USD (default: 0.50)
export KS_ANALYSIS_BUDGET="1.00"

# Minimum events to trigger analysis (default: 5)
export KS_MIN_EVENTS_FOR_ANALYSIS="10"
```

### Monitoring Background Processing

```bash
# View current state
tools/plumbing/schedule-analysis-cycles --status

# Monitor processes
tools/plumbing/monitor-background-processes --status

# Check logs
tail -f knowledge/.background/analysis.log
```

The system automatically tracks spending, respects daily budgets, and creates notifications when insights are discovered.

### Testing Before Production Use

**Important**: Test daemon stability for 2-3 days before relying on automated scheduling.

1. Start daemon: `tools/plumbing/schedule-analysis-cycles --daemon`
2. Monitor logs: `tail -f knowledge/.background/analysis.log`
3. Verify hourly execution and check for crashes
4. Stop test: `kill $(cat knowledge/.background/daemon.pid)`

Only install as a system service after successful multi-day testing.

## Architecture Benefits

- **Context separation**: Conversation vs analysis modes
- **Clean tool interfaces**: Explicit prompts via `claude --print`
- **Symlinked access**: Tools work from conversation context
- **Extensible**: Easy to add new analysis capabilities