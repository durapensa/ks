# Knowledge System Tools

## Core Tools

### Capture
- `capture/events` (ke) - Append events to knowledge stream
- `capture/query` (kq) - Search across events and knowledge

### Analyze
- `analyze/extract-themes` - Extract key themes using AI
  - `--format [text|json|markdown]` - Output format
  - `--days N` - Time range filter
  - `--type TYPE` - Event type filter
- `analyze/find-connections` - Find conceptual connections
  - `--format [text|json|markdown]` - Output format
  - `--days N` - Time range filter
  - `--topic TOPIC` - Topic filter

### Process
- `process/rotate-logs` - Rotate and archive event logs
  - `--max-size BYTES` - Size threshold
  - `--max-age HOURS` - Age threshold
  - `--max-events COUNT` - Event count threshold
  - `--force` - Force rotation

### Utils
- `utils/validate-jsonl` - Validate JSONL file format integrity
- `utils/migrate-to-jsonl.py` - Convert multi-line JSON to JSONL format

## Format Requirements

All event files must use JSONL (JSON Lines) format:
- Each line is a complete, valid JSON object
- No pretty-printing or multi-line formatting
- Each event contains: ts, type, topic, content, metadata

## Development

See GitHub issues for active development priorities:
```bash
gh issue list
```