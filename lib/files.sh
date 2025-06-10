#!/usr/bin/env bash
# Knowledge System Files Library
# Functions for file collection and processing

ks_collect_files() {
    # Collect JSONL files in chronological order (hot log first, then archives)
    # Usage: ks_collect_files
    # Outputs: Array of file paths via global FILES_TO_PROCESS variable
    
    FILES_TO_PROCESS=()
    
    # Add hot log if it exists and has content
    if [[ -f "$KS_HOT_LOG" && -s "$KS_HOT_LOG" ]]; then
        FILES_TO_PROCESS+=("$KS_HOT_LOG")
    fi
    
    # Add archive files in reverse chronological order
    if [[ -d "$KS_ARCHIVE_DIR" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -f "$file" && -s "$file" ]]; then
                FILES_TO_PROCESS+=("$file")
            fi
        done < <(find "$KS_ARCHIVE_DIR" -name "*.jsonl" -type f -print0 | sort -zr)
    fi
}