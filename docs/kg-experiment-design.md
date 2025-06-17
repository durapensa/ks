# Knowledge Graph Logex Experiment Design

*Created: 2025-06-17*  
*Purpose: Design experiments for Issue #20 to discover conceptual attractors through Claude-Claude dialogue*

## Experimental Framework

The logex conversation harness provides a unique opportunity to study how concepts form, consolidate, and evolve during AI-AI dialogue. This framework tests specific hypotheses about knowledge graph formation patterns.

## Core Research Questions

1. **Concept Formation**: How do new concepts crystallize during extended dialogue?
2. **Conceptual Attractors**: Which concepts naturally emerge as conversation focal points?
3. **Relationship Discovery**: How do concept relationships strengthen over dialogue rounds?
4. **Knowledge Consolidation**: How do different dialogue styles affect concept formation quality?

## Experimental Design

### Experiment 1: Concept Formation Dynamics
**Configuration**: `concept-formation-test`
- **Participants**: Physicist-Claude vs Philosopher-Claude
- **Topic**: "How do new scientific concepts emerge from existing knowledge?"
- **Rounds**: 15 (30 total turns)
- **Expected Patterns**: 
  - Emergence concepts: novelty, paradigm-shift, discovery
  - Process concepts: hypothesis, validation, peer-review
  - Bridge concepts: intuition, creativity, logic

**Hypothesis**: Interdisciplinary dialogue creates richer concept networks than single-domain discussion.

### Experiment 2: Cross-Domain Knowledge Transfer  
**Configuration**: `knowledge-transfer-test`
- **Participants**: Systems-Theorist-Claude vs Software-Architect-Claude
- **Topic**: "Connections between complexity science and software architecture"
- **Rounds**: 20 (40 total turns)
- **Expected Patterns**:
  - System concepts: emergence, hierarchy, feedback-loops
  - Architecture concepts: modularity, coupling, cohesion
  - Bridge concepts: patterns, scalability, robustness

**Hypothesis**: Cross-domain conversations generate stronger analogical relationships.

### Experiment 3: Knowledge Consolidation
**Configuration**: `consolidation-test`  
- **Participants**: Database-Expert-Claude vs Network-Engineer-Claude
- **Topic**: "Distributed systems consensus mechanisms"
- **Rounds**: 25 (50 total turns)
- **Expected Patterns**:
  - Core concepts: consensus, consistency, partition-tolerance
  - Technical concepts: raft, paxos, byzantine-fault-tolerance
  - Quality concepts: reliability, availability, performance

**Hypothesis**: Expert-level dialogue produces higher-weight, more stable concepts.

### Experiment 4: Relationship Discovery
**Configuration**: `relationship-test`
- **Participants**: Evolutionary-Biologist-Claude vs Senior-Developer-Claude  
- **Topic**: "Apply biological evolution principles to software development"
- **Rounds**: 25 (50 total turns)
- **Expected Patterns**:
  - Evolution concepts: selection, mutation, adaptation
  - Development concepts: iteration, refactoring, testing
  - Analogical relationships: natural-selection ↔ code-review, mutation ↔ experimentation

**Hypothesis**: Metaphorical conversations create distinct relationship patterns from literal discussions.

## Analysis Framework

### Conceptual Attractor Detection

**SQL Query Pattern**:
```sql
-- Find concepts that appear consistently across dialogue rounds
SELECT concept_name, COUNT(DISTINCT round_number) as rounds_mentioned,
       AVG(concept_weight) as avg_weight
FROM concepts c
JOIN events e ON c.source_event = e.id  
WHERE conversation_id = ?
GROUP BY concept_name
HAVING rounds_mentioned >= 3
ORDER BY rounds_mentioned DESC, avg_weight DESC;
```

**Implementation**: `tools/analyze/conceptual-attractors`

### Relationship Emergence Tracking

**SQL Query Pattern**:
```sql
-- Track how relationships strengthen over conversation rounds
SELECT source_concept, target_concept, relationship_type,
       MIN(round_number) as first_mention,
       MAX(round_number) as last_mention,
       COUNT(*) as total_mentions,
       AVG(relationship_strength) as avg_strength
FROM relationships r
JOIN events e ON r.source_event = e.id
WHERE conversation_id = ?
GROUP BY source_concept, target_concept, relationship_type
ORDER BY avg_strength DESC;
```

**Implementation**: `tools/analyze/relationship-emergence`

### Knowledge Consolidation Measurement

**SQL Query Pattern**:
```sql
-- Measure concept definition stability across rounds
SELECT concept_name,
       COUNT(DISTINCT definition_hash) as definition_variations,
       MAX(concept_weight) - MIN(concept_weight) as weight_evolution,
       CASE WHEN MAX(round_number) - MIN(round_number) > 10 
            THEN 'persistent' ELSE 'ephemeral' END as concept_durability
FROM concepts c
JOIN events e ON c.source_event = e.id
WHERE conversation_id = ?
GROUP BY concept_name
ORDER BY weight_evolution DESC;
```

**Implementation**: `tools/analyze/knowledge-consolidation`

## Integration with Existing Infrastructure

### Event Capture
- Conversations write to `experiments/{experiment-name}/knowledge/events/hot.jsonl`
- Background analysis processes extract concepts automatically
- Knowledge graph distillation runs after conversation completion

### Real-Time Monitoring
- ksd monitors `hot.jsonl` during conversation execution
- Concept formation visible in real-time
- Manual intervention possible if conversations go off-track

### Analysis Pipeline
```bash
# Run experiment
cd experiments/concept-formation-test
ks logex orchestrate-worker

# Monitor (separate terminal)
cd experiments/concept-formation-test  
ksd

# Analyze results
ks conceptual-attractors concept-formation-test
ks relationship-emergence concept-formation-test  
ks knowledge-consolidation concept-formation-test
```

## Expected Insights

### For Knowledge Graph Enhancement
1. **Concept Deduplication**: Which concepts are actually the same vs genuinely different?
2. **Relationship Weighting**: How should relationship strength evolve over time?
3. **Cross-Reference Optimization**: Which dialogue moments produce the strongest concepts?
4. **Temporal Patterns**: How do concept weights naturally decay or strengthen?

### For Development Prioritization
- If concept formation patterns are consistent, prioritize clustering algorithms
- If relationship discovery is noisy, focus on better inference methods
- If consolidation varies by dialogue style, develop persona-aware processing
- If cross-domain transfer creates valuable insights, enhance analogical reasoning

## Validation Against Mechanistic Interpretability

Compare results with recent research on concept formation in large language models:
- Do dialogue-emergent concepts match internal model representations?
- Are AI-AI discovered relationships consistent with human intuitions?
- How do conversation-level attractors relate to model-level feature activations?

## Next Phase Development

Based on experimental results, prioritize:
1. **High-value patterns**: Implement features that support discovered patterns
2. **Gap areas**: Address weaknesses revealed by experiments  
3. **Scale considerations**: Optimize for patterns that emerge at larger conversation scales
4. **Human integration**: Enhance areas where human insight adds most value

This experimental framework transforms Issue #20 from theoretical feature requests into data-driven development priorities based on empirical AI-AI dialogue patterns.