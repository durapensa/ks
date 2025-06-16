#!/usr/bin/env bash
# Category-based option pattern definitions

# Standard option sets by tool category
declare -gA KS_CATEGORY_OPTIONS

# ANALYZE: AI analysis tools (ks Claude occasional, Claude Code testing, background auto)
# Moderate complexity - used across contexts
KS_CATEGORY_OPTIONS["ANALYZE"]="days|d|Analyze events from last N days|7
since|s|Analyze events since ISO date|
type|t|Filter by event type|
topic|p|Filter by topic metadata|
format|f|Output format|text
verbose|v|Show detailed output|BOOL"

# CAPTURE: Knowledge I/O tools (ks Claude primary use)
# Split patterns for input vs search
KS_CATEGORY_OPTIONS["CAPTURE_INPUT"]="format|f|Output format|text"

KS_CATEGORY_OPTIONS["CAPTURE_SEARCH"]="days|d|Search last N days|
since||Search since ISO date|
search||Search term|
type|t|Filter by event type|
topic|p|Filter by topic|
limit|l|Limit results|20
reverse|r|Show oldest first|BOOL
count|c|Show count only|BOOL"

# PLUMBING: System infrastructure (Claude Code diagnostic, background auto)  
# Rich diagnostic options
KS_CATEGORY_OPTIONS["PLUMBING"]="verbose|v|Show detailed output|BOOL
dry-run|n|Show what would be done|BOOL
force|f|Force operation|BOOL
status|s|Show status|BOOL
active||Show active only|BOOL
completed||Show completed only|BOOL
failed||Show failed only|BOOL
cleanup||Clean up stale entries|BOOL
kill-stale||Kill stale processes|BOOL
history||Show process history|BOOL
archive-old|a|Archive records older than N days|
json-output|j|Machine-readable JSON output|BOOL"

# INTROSPECT: Human reflection tools (dashboard/ksd usage)
# Rich interactive interfaces
KS_CATEGORY_OPTIONS["INTROSPECT"]="list|l|List pending items without reviewing|BOOL
batch-size|b|Review N items at once|5
detailed|d|Show detailed analysis|BOOL
interactive|i|Enable interactive mode|BOOL
confidence-threshold|c|Filter by confidence level|0.5
show-context||Include source events|BOOL
auto-approve|a|Auto-approve above threshold|BOOL"

# LOGEX: Dialogue composer tools (automated conversation orchestration)
# Interactive configuration and process supervision
KS_CATEGORY_OPTIONS["LOGEX"]="verbose|v|Show detailed output|BOOL
dry-run|n|Show what would be done|BOOL
force|f|Force operation|BOOL
template|t|Use configuration template|
output|o|Output file path|
status|s|Show status|BOOL"

# UTILS: Specialized tools (per-tool unique options)
KS_CATEGORY_OPTIONS["UTILS"]=""  # Utilities define their own options


# Note: Legacy ks_tool_category function has been removed.
# All tools now use the category-based code generation system via tools/utils/generate-argparse