# Knowledge System Utilities

General-purpose utilities for maintaining the knowledge system.

## validate-jsonl

Validates that a file is in proper JSONL (JSON Lines) format.

```bash
./validate-jsonl <file>
```

Features:
- Checks each line is valid JSON
- For knowledge event files, validates required fields (ts, type, topic, content)
- Returns exit code 0 for valid files, 1 for invalid

## migrate-to-jsonl.py

Converts multi-line JSON format to proper JSONL format.

```bash
python3 migrate-to-jsonl.py <input_file> <output_file>
```

Features:
- Extracts valid JSON objects from corrupted multi-line format
- Writes each object as a single line (JSONL)
- Validates output before completing
- Preserves all data during migration

This tool was created to fix issue #8 where the event log was corrupted with pretty-printed JSON instead of JSONL format.