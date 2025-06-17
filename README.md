# ks: Personal Knowledge System

An event-sourced knowledge management system that captures thoughts, insights, and connections through natural conversation and transforms them into searchable, structured knowledge using AI analysis and human curation.

## Features

- **Event-Sourced Architecture**: Append-only knowledge capture with complete provenance
- **Conversational Interface**: Natural interaction via Claude AI for knowledge capture
- **Automated Analysis**: Background AI processing extracts themes, connections, and patterns
- **Human-in-the-Loop Curation**: Review and approve AI insights before integration
- **Knowledge Graph**: SQLite-based distilled knowledge with concept relationships
- **Real-Time Dashboard**: Live monitoring of capture activity and analysis status
- **Conversation Harness**: Automated AI-to-AI dialogues for knowledge experiments
- **Local-First**: All data stored on your filesystem, no cloud dependencies

## Quick Start

### Installation

```bash
git clone https://github.com/durapensa/ks.git
cd ks
./setup.sh
source ~/.zshrc  # or your shell config file
```

The setup script will check for dependencies and offer to install missing ones via your package manager.

### Basic Usage

**Recommended Setup**: Use two side-by-side terminals for the optimal experience:

```bash
# Terminal 1: Interactive knowledge capture
ks

# Terminal 2: Real-time dashboard (optional)
ksd
```

This setup provides live monitoring of your knowledge system activity while you capture thoughts and insights through natural conversation.

**Screenshots and visual examples coming soon.**

### Core Workflow

1. **Capture Knowledge**: Use `ks` to enter conversational mode with Claude
2. **Automatic Processing**: Background analysis extracts insights when event thresholds are reached
3. **Review Findings**: Approve or reject AI-generated insights via the dashboard or review tools
4. **Query Knowledge**: Search and explore your accumulated knowledge using various tools

### Example Usage

```bash
# Start interactive knowledge session
ks

# During conversation, Claude automatically captures events like:
# - New thoughts and observations
# - Connections between concepts  
# - Questions for future exploration
# - Synthesized insights

# Search your knowledge
ks query "memory systems"
ks query --type thought --days 30

# Direct event capture (alternative to conversation)
ks events thought "distributed-systems" "CAP theorem creates interesting trade-offs"

# View system status
ksd --status

# Review pending AI analysis
ks review-findings
```

## System Requirements

- **Operating System**: macOS or Linux
- **Shell**: bash 5.x+ (installed by setup.sh if needed)
- **Claude CLI**: Required for AI interactions ([installation guide](https://claude.ai/cli))

### Dependencies

**Core Requirements** (checked/installed by setup.sh):
- `jq` - JSON processing
- `claude` - Claude AI CLI
- `python3` - For utilities (typically pre-installed)
- GNU coreutils, findutils, util-linux - Cross-platform compatibility

**Additional Tools** (for enhanced functionality):
- `sd` - Modern text processing 
- `ripgrep` (rg) - Fast search
- `parallel` - Concurrent processing
- `fx` - JSON exploration (integrated with dashboard)

## Configuration

```bash
# Set Claude model for analysis (default: sonnet)
export KS_MODEL=opus    # Deeper analysis
export KS_MODEL=sonnet  # Faster processing (default)

# Adjust background analysis triggers
export KS_EVENT_THRESHOLD_THEMES=10      # Theme extraction trigger
export KS_EVENT_THRESHOLD_CONNECTIONS=20 # Connection analysis trigger
export KS_EVENT_THRESHOLD_PATTERNS=30    # Pattern recognition trigger
```

## Key Capabilities

### Knowledge Capture

- **Interactive Conversations**: Natural dialogue with Claude for thought development
- **Automatic Event Creation**: Thoughts, insights, and connections captured during conversation
- **Direct Event Logging**: Command-line tools for quick knowledge entry
- **Multiple Event Types**: thoughts, insights, connections, questions, observations

### AI-Powered Analysis

- **Theme Extraction**: Identifies recurring topics and concepts in your thinking
- **Connection Discovery**: Finds non-obvious relationships between ideas
- **Pattern Recognition**: Detects recurring thought patterns and habits
- **Background Processing**: Automatic analysis when event thresholds are reached

### Knowledge Graph

- **Concept Distillation**: Extracts and weights core concepts from event streams
- **Relationship Mapping**: Tracks connections between concepts with strength indicators
- **Source Attribution**: Maintains human vs AI contribution tracking
- **Query Interface**: Rich exploration of distilled knowledge

### Conversation Experiments

The system includes automated conversation capabilities for research and experimentation:

- **AI-to-AI Dialogues**: Configure Claude instances to discuss topics automatically
- **Experiment Framework**: YAML-based conversation orchestration
- **Knowledge Capture**: Conversation insights integrated into knowledge graph

See [tools/logex/README.md](tools/logex/README.md) for detailed information about conversation experiments and automated dialogue capabilities.

## Project Structure

```
ks/
├── ks                          # Main CLI entry point
├── ksd                         # Real-time dashboard (Go TUI)
├── setup.sh                   # Installation and dependency management
├── knowledge/                  # Your data (gitignored)
│   ├── events/                 # Event streams (JSONL format)
│   ├── derived/                # Processed insights and rejections
│   └── kg.db                   # Knowledge graph database
├── tools/                      # Processing utilities
│   ├── capture/                # Event logging and search
│   ├── analyze/                # AI-powered analysis tools
│   ├── kg/                     # Knowledge graph operations
│   ├── introspect/             # Human review and curation
│   ├── logex/                  # Conversation experiments
│   └── plumbing/               # System infrastructure
├── lib/                        # Core libraries
├── tests/                      # Comprehensive test suite
└── docs/                       # System documentation
```

## Data Format

Knowledge is stored in JSONL (JSON Lines) format - one JSON object per line:

```json
{"ts":"2025-06-17T10:30:00Z","type":"thought","topic":"systems","content":"Event sourcing provides audit trail...","metadata":{}}
{"ts":"2025-06-17T10:31:00Z","type":"connection","topic":"architecture","content":"Event sourcing relates to CQRS pattern"}
```

This format is:
- Grep-friendly for quick searches
- Streamable for real-time processing  
- Robust against partial writes
- Human-readable for inspection

## Tool Categories

All tools follow consistent argument patterns organized by category:

- **Capture** (`tools/capture/`): Event logging and search
- **Analyze** (`tools/analyze/`): AI-powered pattern extraction
- **Knowledge Graph** (`tools/kg/`): Concept distillation and querying
- **Introspect** (`tools/introspect/`): Human review and curation
- **Logex** (`tools/logex/`): Conversation experiments and automation
- **Plumbing** (`tools/plumbing/`): System infrastructure and monitoring
- **Utils** (`tools/utils/`): Specialized utilities and validation

Each tool provides `--help` for detailed usage information.

## Background Processing

The system automatically analyzes your knowledge as you capture it:

1. **Event Thresholds**: Analysis triggers when you reach configurable event counts
2. **Background Analysis**: AI processing runs automatically without interrupting your workflow
3. **Review Queue**: Findings await your approval before integration
4. **Human Curation**: You control which insights become part of your knowledge base

Monitor background activity via the dashboard (`ksd`) or status commands.

## Testing and Development

### Running Tests

```bash
# Fast tests (no AI API calls, ~30 seconds)
./tests/run_fast_tests.sh

# Mocked tests (fake AI responses, ~60 seconds)  
./tests/run_mocked_tests.sh

# End-to-end tests (real Claude API, ~5 minutes, local only)
./tests/run_e2e_tests.sh
```

### Development Workflow

```bash
# Check current priorities
gh issue list --label "priority: high"

# Run development tests
./tests/run_fast_tests.sh

# Check system implementation status
cat docs/implementation-status.md
```

## Architecture Philosophy

- **Local-First**: Your knowledge stays on your filesystem
- **Event-Sourced**: Complete audit trail of knowledge development
- **Human-in-the-Loop**: AI assists, humans decide what knowledge to keep
- **Modular Design**: Composable tools following Unix philosophy
- **Research-Oriented**: Built for exploration and experimentation

## Contributing

### Development Setup

1. Fork and clone the repository
2. Run `./setup.sh` to install dependencies
3. Familiarize yourself with the tool conventions in `CLAUDE.md`
4. Run tests to ensure everything works: `./tests/run_fast_tests.sh`

### Code Conventions

- All tools follow category-based argument parsing
- Consistent error handling and library usage
- Comprehensive test coverage required
- See `CLAUDE.md` for detailed development guidelines

### Current Development Focus

See `docs/implementation-status.md` for current priorities and `gh issue list` for active work items.

## Documentation

- `docs/ks-system-analysis.md` - Comprehensive system overview
- `docs/implementation-status.md` - Current development status
- `docs/kg-implementation-status.md` - Knowledge graph capabilities
- `docs/testing-strategy.md` - Testing approach and coverage
- `tools/logex/README.md` - Conversation experiment framework
- Individual tool documentation via `<toolname> --help`

## License

MIT License - see LICENSE file for details.

## Research Context

This is ongoing research software exploring personal knowledge management, AI-assisted thinking, and automated conversation systems. The system is functional and tested but continues to evolve based on experimental findings and usage patterns.