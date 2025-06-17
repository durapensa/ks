# ks: Personal Knowledge System Analysis

## Executive Summary

The ks system is a sophisticated personal knowledge management platform that captures thoughts, insights, and observations through natural conversation and transforms them into structured, searchable knowledge through automated analysis and human curation. Built on an event-sourced architecture, it provides both immediate capture capabilities and long-term knowledge distillation.

## System Architecture

### Core Design Principles

**Event-Sourced Architecture**: All knowledge enters the system as discrete events in append-only JSONL logs. This design ensures complete provenance, enables temporal analysis, and supports safe experimentation with processing logic.

**Human-in-the-Loop AI Analysis**: Background AI processes automatically extract themes, connections, and patterns, but all insights require human review and approval before integration into the distilled knowledge base.

**Modular Tool Ecosystem**: The system is built as composable command-line tools organized by function, each following consistent argument parsing, error handling, and library usage patterns.

**Context-Aware Operation**: The system can operate both globally (single knowledge base) and in conversation-specific contexts with isolated knowledge directories.

### File Structure

```
ks/
├── ks                          # Main CLI entry point
├── ksd                         # Dashboard TUI application  
├── .ks-env                     # Environment configuration
├── setup.sh                   # System setup and dependency management
├── knowledge/                  # Personal data (gitignored)
│   ├── events/
│   │   ├── hot.jsonl          # Current session events
│   │   └── archive/           # Rotated event logs
│   ├── derived/
│   │   ├── approved.jsonl     # Human-approved insights
│   │   ├── rejected.jsonl     # Rejected findings for learning
│   │   └── stream.jsonl       # Claude-generated events
│   ├── kg.db                  # SQLite knowledge graph
│   └── .background/           # Background process state
├── lib/                       # Core libraries
├── tools/                     # Categorized tool collection
├── go/                        # Go components (ksd dashboard)
└── chat/                      # Claude conversation context
```

### Data Flow

1. **Capture**: Events enter via `tools/capture/events` as structured JSONL
2. **Trigger**: Background monitors watch for event count thresholds
3. **Analysis**: AI tools extract themes, connections, patterns automatically  
4. **Review**: Human curation via `tools/introspect/review-findings`
5. **Integration**: Approved insights flow to `derived/approved.jsonl`
6. **Distillation**: Knowledge graph extraction from approved insights
7. **Query**: Search across raw events and distilled knowledge

## Core Workflows

### Daily Knowledge Capture

**Interactive Mode** (`ks`):
- Launches Claude conversation with knowledge context
- Automatic event creation for significant thoughts/insights
- Real-time integration with analysis triggers

**Direct Capture** (`ks events TYPE TOPIC [CONTENT]`):
- Immediate structured event logging
- Support for piped content and stdin
- Automatic background analysis triggering

**Event Types**:
- `thought`: New ideas or observations
- `insight`: Synthesized understanding  
- `connection`: Links between concepts
- `question`: Open questions to explore
- `process`: System operations (auto-generated)

### Background Analysis Pipeline

**Automatic Triggers**:
- Theme extraction: Every 10 events (configurable)
- Connection finding: Every 20 events
- Pattern analysis: Every 30 events

**Analysis Process**:
1. Event threshold reached → background analysis spawned
2. Claude processes recent events → generates findings JSON
3. Findings queued for human review
4. User notified via dashboard or CLI

**Quality Control**:
- All AI findings require explicit human approval
- Rejection reasons captured for model improvement
- Approved insights integrate into knowledge base
- Full audit trail maintained

### Knowledge Exploration

**Event Search** (`tools/capture/query`):
- Full-text search across all events
- Filtering by type, topic, timeframe
- Support for complex queries and result limiting

**Knowledge Graph Queries** (`tools/kg/query`):
- SQLite-based structured queries
- Concept statistics and relationship exploration
- Raw SQL access for advanced analysis

**Dashboard Monitoring** (`ksd`):
- Real-time event counts and analysis status
- Latest event preview with intelligent content wrapping
- Pending review notifications
- Quick access to common operations

## Tool Ecosystem

### Capture Tools
- **events**: Primary event logging with automatic processing triggers
- **query**: Event search and retrieval with flexible filtering

### Analysis Tools  
- **extract-themes**: Identifies recurring themes in thought patterns
- **find-connections**: Discovers non-obvious relationships between concepts
- **identify-recurring-thought-patterns**: Recognizes behavioral patterns
- **curate-duplicate-knowledge**: Prevents knowledge graph pollution

### Knowledge Graph Tools
- **extract-concepts**: Distills events into structured concept nodes
- **query**: Explores the SQLite knowledge graph
- **run-distillation**: Orchestrates full knowledge graph updates

### Introspection Tools
- **review-findings**: Interactive human curation of AI-generated insights

### Plumbing Tools
- **check-event-triggers**: Monitors thresholds and spawns analysis
- **monitor-background-processes**: Process lifecycle management  
- **rotate-logs**: Event log archival and cleanup

### Utility Tools
- **generate-argparse**: Code generation for consistent CLI patterns
- **validate-jsonl**: Data integrity verification

## Technical Implementation

### Event Format (JSONL)

```json
{
  "ts": "2025-06-17T10:30:00Z",
  "type": "thought", 
  "topic": "learning",
  "content": "Discovered interesting pattern in data processing",
  "metadata": {"source": "claude-conversation"}
}
```

**Design Benefits**:
- One complete JSON object per line
- Grep-friendly for quick searches
- Streamable for real-time processing
- Robust against partial writes

### Library System

**Core Libraries** (`lib/`):
- **core.sh**: Essential utilities, directory management, validation
- **events.sh**: Event validation and counting
- **files.sh**: JSONL file collection and ordering
- **categories.sh**: Argument parsing category definitions
- **validation.sh**: Input validation and sanitization

**Tool Libraries** (`tools/lib/`):
- **claude.sh**: AI analysis integration and formatting
- **queue.sh**: Background analysis queue management
- **process.sh**: Background process tracking
- **analysis.sh**: Business logic for analysis tools

### Argument Parsing System

**Category-Based Approach**:
- **ANALYZE**: AI analysis tools (days, since, type, format, verbose)
- **CAPTURE_SEARCH**: Search tools (days, search, type, limit, reverse)
- **CAPTURE_INPUT**: Event capture (custom positional arguments)
- **PLUMBING**: Infrastructure tools (verbose, dry-run, force, status)
- **INTROSPECT**: Review tools (batch-size, detailed, interactive)
- **UTILS**: Specialized tools with custom argument patterns

**Benefits**:
- Consistent UX across all tools
- Reduced code duplication
- Automatic help generation
- Standardized error handling

### Background Processing

**Event-Driven Architecture**:
- File system watchers detect new events
- Threshold calculations trigger analysis spawning
- Process registry tracks active/completed/failed analyses
- Queue system manages pending human reviews

**Concurrency Model**:
- Background analyses run asynchronously
- Multiple analysis types can execute simultaneously
- Human review operates independently of analysis generation
- Dashboard provides real-time status monitoring

## Knowledge Graph Schema

### SQLite Schema Design

```sql
-- Core concepts with weighted importance
CREATE TABLE concepts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    weight REAL DEFAULT 1.0,
    human_weight REAL DEFAULT 0,
    ai_weight REAL DEFAULT 0,
    created TEXT NOT NULL,
    updated TEXT NOT NULL
);

-- Typed relationships between concepts
CREATE TABLE edges (
    source_id TEXT NOT NULL,
    target_id TEXT NOT NULL,
    edge_type TEXT NOT NULL,  -- 'relates', 'causes', 'contradicts'
    strength REAL DEFAULT 1.0,
    created TEXT NOT NULL,
    PRIMARY KEY (source_id, target_id, edge_type)
);

-- Concept aliases for normalization
CREATE TABLE aliases (
    canonical_id TEXT NOT NULL,
    alias TEXT NOT NULL,
    source TEXT,
    count INTEGER DEFAULT 1,
    PRIMARY KEY (canonical_id, alias)
);
```

**Design Philosophy**:
- Minimal, extensible schema
- Weight-based concept importance
- Human/AI contribution tracking
- Full relationship type support
- Alias handling for concept variations

## User Experience Design

### Command-Line Interface

**Main Entry Point** (`ks`):
- No arguments: Launch interactive Claude conversation
- Subcommands: Direct tool access (`ks events`, `ks query`)
- Help system: `--claudehelp` for key tools, `--allhelp` for everything

**Tool Discovery**:
- Automatic scanning of `tools/` directory
- Category-based organization in help output
- Parallel help generation for performance
- Consistent argument patterns across tools

### Dashboard Application (`ksd`)

**Real-Time Monitoring**:
- Live event counts with file system watching
- Analysis trigger status (events until next analysis)
- Pending review notifications
- Latest event preview with intelligent text wrapping

**Interactive Features**:
- Multi-screen navigation (Dashboard, Search, Analytics, Processes)
- Keyboard shortcuts for common operations
- External tool launching (fx for JSON exploration)
- Context-aware operation (conversation vs global mode)

**Visual Design**:
- Clean terminal UI with lipgloss styling
- Color-coded status indicators
- Responsive layout adaptation
- Help text contextual to current screen

## Human Usage Patterns

### For Knowledge Workers

**Daily Capture Routine**:
1. Start `ks` for interactive thought capture during work
2. Let background analysis run automatically
3. Review findings weekly via `review-findings`
4. Query knowledge base when solving similar problems

**Research Workflow**:
1. Capture research notes and observations as events
2. Use `extract-themes` to identify patterns in research areas
3. Leverage `find-connections` to discover unexpected relationships
4. Build literature review from accumulated insights

**Problem-Solving Process**:
1. Document problem as `question` event
2. Search existing knowledge for related insights
3. Capture solution attempts and outcomes
4. Extract patterns for future problem-solving

### For Personal Development

**Reflection Practice**:
1. Daily thought capture in `ks` interactive mode
2. Weekly theme review to identify personal patterns
3. Monthly connection analysis for deeper insights
4. Quarterly knowledge graph exploration

**Learning Tracking**:
1. Capture learning events with specific topics
2. Use pattern analysis to identify effective learning methods
3. Track concept development over time
4. Build personal curriculum from identified gaps

**Decision Making**:
1. Document decision context and criteria
2. Search for similar past decisions and outcomes
3. Use connection analysis to understand decision patterns
4. Track decision quality over time

### For Creative Work

**Idea Development**:
1. Rapid idea capture without evaluation
2. Background theme extraction reveals creative directions
3. Connection finding links disparate concepts
4. Knowledge graph exploration sparks new combinations

**Project Planning**:
1. Capture project requirements and constraints
2. Search for relevant past project experiences
3. Use pattern analysis to identify successful approaches
4. Build project knowledge base for team sharing

## Claude Integration Possibilities

### As a Research Assistant

**Hypothesis Generation**:
- Analyze event patterns to suggest research directions
- Identify gaps in knowledge capture for investigation
- Generate testable hypotheses from connection patterns
- Suggest experimental designs based on past approaches

**Literature Integration**:
- Process external research papers into knowledge events
- Cross-reference with personal insights for novel connections
- Identify conflicting findings requiring investigation
- Build comprehensive research maps

### As a Knowledge Curator

**Quality Enhancement**:
- Suggest better event categorization and tagging
- Identify redundant or overlapping insights for consolidation
- Recommend knowledge graph refinements
- Propose new concept relationships

**Pattern Recognition**:
- Detect subtle patterns humans might miss
- Identify temporal trends in thinking patterns
- Suggest optimal review schedules based on forgetting curves
- Recommend focus areas based on knowledge density

### As an Analytical Partner

**Meta-Analysis**:
- Analyze the knowledge system's own effectiveness
- Identify optimal capture and review workflows
- Suggest system configuration improvements
- Track knowledge growth and utilization patterns

**Collaborative Thinking**:
- Engage in structured dialogue to develop complex ideas
- Challenge assumptions embedded in knowledge patterns
- Suggest alternative interpretations of data
- Facilitate creative connections between distant concepts

### Experimental Approaches

**Automated Knowledge Synthesis**:
- Generate summary reports of knowledge domains
- Create concept maps from knowledge graph data
- Build timeline visualizations of idea development
- Generate knowledge gap analyses

**Interactive Exploration**:
- Natural language querying of knowledge base
- Conversational knowledge graph traversal
- Dynamic insight generation during exploration
- Real-time connection suggestion during capture

**Knowledge Evolution Tracking**:
- Monitor concept development over time
- Track belief and opinion changes
- Identify knowledge consolidation opportunities
- Suggest periodic knowledge base maintenance

**Cross-Domain Connection Discovery**:
- Link insights across completely different domains
- Identify transferable patterns and principles
- Suggest novel applications of existing knowledge
- Generate interdisciplinary research questions

## Future Development Potential

### System Enhancements

**Advanced Analytics**:
- Sentiment analysis of captured thoughts
- Concept importance trending over time
- Knowledge utilization frequency tracking
- Collaborative knowledge sharing features

**Enhanced Integration**:
- Import from external knowledge sources (papers, books, articles)
- Export to standard knowledge formats (Obsidian, Roam)
- API development for third-party tool integration
- Mobile capture applications

**Intelligent Automation**:
- Smart event categorization and tagging
- Automated duplicate detection and merging
- Predictive analysis trigger optimization
- Personalized insight generation

### Research Applications

**Knowledge Science**:
- Personal knowledge management research
- Cognitive pattern analysis
- Decision-making process studies
- Creative thinking investigation

**AI Development**:
- Human-AI collaborative reasoning research
- Knowledge representation optimization
- Automated insight quality assessment
- Personalized AI assistant development

The ks system represents a sophisticated approach to personal knowledge management that balances automated processing with human judgment, creating a sustainable workflow for capturing, analyzing, and utilizing personal insights over time. Its modular architecture and research-oriented design make it an excellent platform for exploring the intersection of human cognition and artificial intelligence in knowledge work.