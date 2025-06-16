# Analyze vs KG Tools Architecture

*Document created: 2025-06-16*
*Status: Foundation complete, experimentation phase planned*

## Overview

The ks system implements two complementary knowledge processing architectures serving different cognitive functions:

- **tools/analyze**: "Hot" knowledge for active conversations  
- **tools/kg**: "Cold" knowledge for long-term consolidation

## Architectural Philosophy

### tools/analyze: System 1 Thinking Support
**Purpose**: Real-time insight injection during active thinking
- Ephemeral findings that enhance current dialogue
- Fast, rough analysis optimized for conversation flow
- Background queue system for immediate availability  
- Quality bar: "Interesting enough to inject into conversation"

**Cognitive Function**: Pattern recognition during active thought
- Serendipitous connections while conversing
- "What might I be missing right now?"
- Support for in-the-moment insight discovery

**Implementation Characteristics**:
- Background analysis triggered by event thresholds
- Findings queued for human review during conversations
- Optimized for speed and interestingness over accuracy
- Designed to be disposable after conversation ends

### tools/kg: System 2 Thinking Support  
**Purpose**: Persistent concept graph built over time
- Distilled, validated knowledge for future retrieval
- Thorough analysis optimized for accuracy and relationships
- Context-aware per-conversation accumulation
- Quality bar: "Accurate enough to persist indefinitely"

**Cognitive Function**: Deliberate knowledge organization
- Conceptual framework building over time
- "What do I actually know, and how does it connect?"
- Support for long-term knowledge evolution

**Implementation Characteristics**:
- SQLite-based persistent storage with concepts, edges, aliases
- Context-aware operation (per-conversation knowledge graphs)
- Distillation pipeline for concept extraction and consolidation
- Designed for indefinite persistence and growth

## Current Implementation Status

### tools/analyze (Functional)
- ✅ `extract-themes` - Theme discovery from recent events
- ✅ `find-connections` - Non-obvious relationship detection  
- ✅ `curate-duplicate-knowledge` - Redundancy identification
- ✅ `identify-recurring-thought-patterns` - Pattern recognition
- ✅ Background queue system for automatic analysis
- ✅ Integration with conversation flows via `ks_check_background_results`

### tools/kg (Foundation Complete)
- ✅ `extract-concepts` - Concept extraction with aliases and source attribution
- ✅ `run-distillation` - Database initialization and orchestration
- ✅ `query` - Database exploration and statistics
- ✅ `schema.sql` - SQLite schema with concepts, edges, aliases, distillation tracking
- ✅ Context-aware operation (local vs global knowledge directories)
- 🔄 Relationship extraction and weight calculation (Phase 2 planned)

## Complementary Integration Points

### Shared Infrastructure
- **Concept extraction algorithms**: Both systems need noun phrase extraction, term normalization
- **Claude invocation patterns**: Common API interaction patterns via `tools/lib/claude.sh`
- **Event stream processing**: Shared utilities for JSONL parsing and filtering

### Potential Feedback Loops (Future Experiments)
- **Analyze → KG**: High-confidence analyze findings feed into kg input pipeline
- **KG → Analyze**: KG concept weights inform analyze pattern recognition algorithms  
- **KG → Analyze**: KG relationship discovery seeds analyze connection prompt generation
- **Bidirectional**: Quality assessment - do analyze findings improve when informed by kg concepts?

### Quality Differentiation Strategy
- **analyze**: Experimental/rough quality acceptable (human evaluates in real-time conversation)
- **kg**: Curated/validated quality required (knowledge compounds over time)
- **analyze**: Optimized for serendipity and interesting connections
- **kg**: Optimized for accuracy and persistent conceptual frameworks

## Architectural Decision: Separate but Connected

**Decision**: Keep tools/analyze and tools/kg as separate tool categories but share common libraries and algorithms.

**Rationale**: 
- Different temporal patterns (ephemeral vs persistent)
- Different quality requirements (interesting vs accurate)  
- Different cognitive functions (System 1 vs System 2 thinking)
- Different user interaction modes (background vs intentional)

**Connection Strategy**: Integration at the algorithm/library level, not architectural merger
- Shared concept extraction in `tools/lib/`
- Shared Claude invocation patterns
- Shared event processing utilities
- Potential bidirectional data flows for quality improvement

## Planned Experiments

### Phase 2: Foundational Experiments
1. **Complete KG distillation pipeline** - relationship extraction, weight calculation, edge pruning
2. **Implement TUI dashboard (#23)** - observability for both analyze and kg processes
3. **Test context isolation** - validate per-conversation knowledge graphs work correctly

### Phase 3: Integration Experiments  
1. **Redundancy Detection**: Are we discovering the same insights through both systems?
2. **Quality Convergence**: Do analyze findings improve when informed by kg concept weights?
3. **User Preference Study**: Which system do people reach for in different contexts?
4. **Knowledge Evolution**: Does the two-stage process improve knowledge quality over time?

### Phase 4: Advanced Integration
1. **Bidirectional data flows** - kg concepts → analyze prompts, analyze findings → kg validation
2. **Quality assessment pipelines** - systematic comparison of analyze vs kg insight quality
3. **Adaptive algorithms** - systems that learn from each other's patterns

## Success Metrics

### Short-term (Phase 2)
- KG distillation pipeline functional with real event data
- Both systems operating without conflicts
- Clear performance characteristics documented

### Medium-term (Phase 3)  
- Evidence of complementary value rather than redundancy
- User workflow preferences identified
- Quality improvement measurable when systems inform each other

### Long-term (Phase 4)
- Unified but distinct cognitive support system
- Demonstrable knowledge quality improvement over time
- Scalable architecture for multiple conversation contexts

## Documentation Evolution

This document captures current architectural thinking as of Phase 1 completion (2025-06-16). It should be updated as experiments reveal actual usage patterns and optimal integration strategies.

The fundamental hypothesis: **Different cognitive functions require different knowledge processing architectures, but they can strengthen each other through careful integration.**