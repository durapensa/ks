#!/usr/bin/env bash
# Error handling utilities for consistent error reporting across all tools

# Standard exit codes (with guards to prevent redefinition)
if [[ -z "${EXIT_SUCCESS:-}" ]]; then
    readonly EXIT_SUCCESS=0
    readonly EXIT_ERROR=1
    readonly EXIT_USAGE=2
    readonly EXIT_VALIDATION=3
fi

# Error output functions
ks_error() {
    echo "Error: $1" >&2
}


# Standardized error patterns with exit
ks_exit_usage() {
    ks_error "$1"
    usage
    exit $EXIT_USAGE
}

ks_exit_validation() {
    ks_error "$1"
    exit $EXIT_VALIDATION
}

ks_exit_error() {
    ks_error "$1"
    exit $EXIT_ERROR
}