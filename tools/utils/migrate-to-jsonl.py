#!/usr/bin/env python3
"""
Description: Migrate corrupted multi-line JSON format to proper JSONL format

Each line in JSONL should be a complete, valid JSON object.
"""

import json
import sys
from pathlib import Path

def extract_json_objects(content):
    """Extract valid JSON objects from corrupted file content."""
    objects = []
    current_obj = []
    brace_count = 0
    
    for line in content.split('\n'):
        if line.strip() == '':
            continue
            
        # Count braces to track object boundaries
        brace_count += line.count('{') - line.count('}')
        current_obj.append(line)
        
        # When brace count returns to 0, we have a complete object
        if brace_count == 0 and current_obj:
            obj_text = '\n'.join(current_obj)
            try:
                # Try to parse the JSON object
                obj = json.loads(obj_text)
                objects.append(obj)
            except json.JSONDecodeError as e:
                print(f"Warning: Failed to parse object: {e}", file=sys.stderr)
                print(f"Object text: {obj_text[:100]}...", file=sys.stderr)
            current_obj = []
    
    return objects

def migrate_to_jsonl(input_file, output_file):
    """Convert multi-line JSON file to JSONL format."""
    # Read the corrupted file
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Skip the incomplete first object (lines before first '{')
    first_brace = content.find('\n{')
    if first_brace > 0:
        content = content[first_brace+1:]  # +1 to keep the newline
    
    # Extract valid JSON objects
    objects = extract_json_objects(content)
    
    # Write as JSONL
    with open(output_file, 'w') as f:
        for obj in objects:
            json.dump(obj, f, separators=(',', ':'))
            f.write('\n')
    
    return len(objects)

def validate_jsonl(file_path):
    """Validate that each line is valid JSON."""
    valid_count = 0
    with open(file_path, 'r') as f:
        for i, line in enumerate(f, 1):
            if line.strip():
                try:
                    json.loads(line)
                    valid_count += 1
                except json.JSONDecodeError as e:
                    print(f"Line {i} is not valid JSON: {e}", file=sys.stderr)
                    return False
    return True, valid_count

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: migrate-to-jsonl.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])
    
    if not input_file.exists():
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)
    
    # Perform migration
    print(f"Migrating {input_file} to JSONL format...")
    count = migrate_to_jsonl(input_file, output_file)
    print(f"Extracted {count} events")
    
    # Validate output
    print(f"Validating {output_file}...")
    is_valid, valid_count = validate_jsonl(output_file)
    if is_valid:
        print(f"✓ All {valid_count} lines are valid JSON")
    else:
        print("✗ Validation failed")
        sys.exit(1)