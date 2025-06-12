# DEPRECATED: This file has been replaced by the category-based argument parsing system.
#
# The old declarative argparse.sh library (353 lines) has been replaced with:
# - lib/categories.sh - Category-based option definitions
# - lib/validation.sh - Category-specific validation functions  
# - tools/utils/generate-argparse - Code generator for consistent parsers
# - tools/lib/analysis.sh - Business logic extracted from this file
#
# Migration completed: All 11 tools now use category-based parsing.
#
# For new tools, use:
#   tools/utils/generate-argparse CATEGORY --tool-name name --description "desc"
#
# Benefits of the new system:
# - Single source of truth via categories
# - Generated parsers (no manual duplication)
# - Consistent interfaces across all tools
# - Enhanced maintainability
# - Reduced complexity (~40 lines vs 353 lines per tool)
#
# This file is retained for reference only.
# Original file moved to argparse.sh.original for historical purposes.

echo "ERROR: argparse.sh has been deprecated and replaced by category-based parsing." >&2
echo "Use tools/utils/generate-argparse instead." >&2
exit 1