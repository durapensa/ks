# Introspect Tools

This directory contains tools for human introspection and reflection on AI-generated insights about personal knowledge.

## Tools

- `review-findings` - Interactive review of analysis findings from background processes

## Purpose

Introspect tools are designed for human reflection and decision-making about AI-generated insights. They provide rich, interactive interfaces optimized for human cognitive patterns and decision workflows.

## Usage

These tools are typically accessed through the dashboard (`ksd`) but can also be run directly:

```bash
tools/introspect/review-findings
```

## Option Patterns

Introspect tools use rich interactive option patterns:
- `--batch-size` - Control review workflow pacing
- `--detailed` - Show additional context and analysis
- `--interactive` - Enable rich interactive modes
- `--confidence-threshold` - Filter by AI confidence levels