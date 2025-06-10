#!/usr/bin/env bash
# Knowledge System Claude Library
# Functions for Claude AI integration and analysis

ks_claude() {
    # Wrapper for Claude CLI that unwraps the result
    # Usage: ks_claude [claude options] "prompt"
    # Returns just the actual content, not the metadata wrapper
    
    local result
    result=$(claude "$@")
    
    # Check if it's a wrapped result
    if jq -e '.result' >/dev/null 2>&1 <<< "$result"; then
        # Extract the actual result content
        jq -r '.result' <<< "$result"
    else
        # Return as-is if not wrapped
        echo "$result"
    fi
}

ks_claude_analyze() {
    # Invoke Claude for analysis with standard options and result cleanup
    # Usage: ks_claude_analyze "prompt" [input_data]
    # Example: echo "$CONTENT" | ks_claude_analyze "$KS_PROMPT_THEMES"
    # Returns: Clean JSON output or exits with error
    
    local prompt="$1"
    local input="${2:-$(cat)}"  # Use stdin if no second argument
    
    if [[ -z "$prompt" ]]; then
        echo "Error: ks_claude_analyze requires a prompt" >&2
        return 1
    fi
    
    # Call Claude with standard analysis options
    local result
    result=$(echo "$input" | ks_claude --model "$KS_MODEL" --print --output-format json "$prompt")
    local exit_code=$?
    
    if [[ "$exit_code" -ne 0 ]]; then
        echo "Error: Claude invocation failed" >&2
        return "$exit_code"
    fi
    
    # Clean up markdown code blocks if present
    if grep -q '```json' <<< "$result"; then
        result=$(sed -n '/```json/,/```/p' <<< "$result" | sed '1d;$d')
    fi
    
    # Validate JSON structure
    if ! jq . >/dev/null 2>&1 <<< "$result"; then
        echo "Error: Invalid JSON response from Claude" >&2
        echo "Response was: $result" >&2
        return 1
    fi
    
    echo "$result"
}

ks_format_analysis() {
    # Format analysis JSON output based on requested format
    # Usage: ks_format_analysis <format> <json_data> <title> <jq_markdown> <jq_text>
    # Example: ks_format_analysis "$FORMAT" "$ANALYSIS" "Knowledge Themes" '.themes[]...' '.themes[]...'
    
    local format="$1"
    local json_data="$2"
    local title="$3"
    local jq_markdown="$4"
    local jq_text="$5"
    
    case "$format" in
        json)
            echo "$json_data"
            ;;
        markdown)
            echo "# $title Analysis"
            echo ""
            echo "_Generated at $(date -u '+%Y-%m-%d %H:%M UTC')_"
            echo ""
            jq -r "$jq_markdown" <<< "$json_data"
            ;;
        text|*)
            # Use bash parameter expansion for uppercase conversion
            echo "=== ${title^^} ANALYSIS ==="
            echo "Generated at $(date -u '+%Y-%m-%d %H:%M UTC')"
            echo ""
            # Check for null before trying to iterate
            if jq -e . >/dev/null 2>&1 <<< "$json_data"; then
                jq -r "$jq_text" 2>/dev/null <<< "$json_data" || echo "No data to display"
            else
                echo "No data to display"
            fi
            ;;
    esac
}

# Prompt Templates with Brevity Constraints
# These enforce concise output from Claude to prevent verbose responses

export KS_PROMPT_THEMES='Extract 3-5 key themes from these thoughts. Requirements: Keep responses extremely concise. Return JSON: {themes: [{name: string (max 3 words), description: string (one sentence, max 50 characters), frequency: number (1-10 scale), supporting_quotes: [string] (max 2 quotes, each under 50 characters)}]}'

export KS_PROMPT_CONNECTIONS='Find conceptual connections between these events. Requirements: Be extremely concise. Return JSON: {connections: [{concepts: [string] (exactly 2 items, each max 20 characters), relationship: string (max 30 characters), strength: number (1-10 scale), evidence: string (one phrase, max 50 characters)}]}'

export KS_PROMPT_PATTERNS='Identify recurring thought patterns. Requirements: Ultra-concise responses only. Return JSON: {patterns: [{pattern: string (max 25 characters), description: string (max 50 characters), occurrences: number, examples: [string] (max 2, each under 40 characters)}]}'

export KS_PROMPT_DUPLICATES='Find duplicate or highly similar thoughts. Requirements: Minimal output. Return JSON: {duplicate_groups: [{summary: string (max 40 characters), count: number, sample: string (max 50 characters)}]}'