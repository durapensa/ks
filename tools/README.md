# Knowledge System Tools

## Core Tools

### Capture
- `capture/events` (ke) - Append events to knowledge stream
- `capture/query` (kq) - Search across events and knowledge

### Analyze
- `analyze/extract-themes` - Extract key themes using AI
- `analyze/find-connections` - Find conceptual connections

## Utility Tools

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