# Logex Experiments for Issue #20

*Created: 2025-06-17*  
*Purpose: Systematic Claude-Claude dialogue experiments to discover conceptual attractors*

## Overview

This directory contains four designed experiments that use the logex conversation harness to study how concepts form, evolve, and consolidate during AI-AI dialogue. Each experiment tests specific hypotheses about knowledge graph formation patterns.

## Quick Start

```bash
# Check experiment status
./experiments/run-experiments.sh status

# Run specific experiment with real-time monitoring
./experiments/run-experiments.sh run concept-formation-test

# Monitor experiment (in second terminal)
cd experiments/concept-formation-test
source .ks-env
ksd

# Analyze completed experiment
./experiments/run-experiments.sh analyze concept-formation-test
```

## Experimental Framework

### Research Questions

1. **Concept Formation**: How do new concepts crystallize during extended dialogue?
2. **Conceptual Attractors**: Which concepts naturally emerge as conversation focal points?
3. **Relationship Discovery**: How do concept relationships strengthen over dialogue rounds?
4. **Knowledge Consolidation**: How do different dialogue styles affect concept formation quality?

### Data Collection

Each experiment automatically captures:
- **Event Stream**: Real-time conversation events in `knowledge/events/hot.jsonl`
- **Knowledge Graph**: Extracted concepts and relationships in `knowledge/concepts.db`
- **Full Dialogue**: Complete conversation logs for reference
- **Metadata**: Experiment configuration and execution details

## Experiments

### 1. Concept Formation Dynamics (`concept-formation-test`)

**Participants**: Theoretical Physicist vs Philosophy of Science  
**Topic**: "How do new scientific concepts emerge from existing knowledge?"  
**Duration**: 30 turns (15 per participant)

**Expected Conceptual Attractors**:
- emergence, paradigm-shift, discovery, novelty
- hypothesis, validation, peer-review, scientific-method
- intuition, creativity, logic, mathematical-formalism

**Hypothesis**: Interdisciplinary dialogue creates richer concept networks than single-domain discussion.

**Key Questions**:
- How do empirical vs epistemological perspectives shape concept formation?
- Which concepts persist across both scientific and philosophical viewpoints?
- What bridge concepts emerge between domains?

### 2. Cross-Domain Knowledge Transfer (`knowledge-transfer-test`)

**Participants**: Systems Theorist vs Software Architect  
**Topic**: "Connections between complexity science and software architecture"  
**Duration**: 40 turns (20 per participant)

**Expected Conceptual Attractors**:
- emergence, hierarchy, feedback-loops, complexity
- modularity, coupling, cohesion, scalability
- patterns, robustness, adaptation, self-organization

**Hypothesis**: Cross-domain conversations generate stronger analogical relationships.

**Key Questions**:
- How do abstract theoretical concepts map to concrete technical implementations?
- Which analogies prove most robust across domains?
- What novel insights emerge from cross-pollination?

### 3. Knowledge Consolidation (`consolidation-test`)

**Participants**: Database Expert vs Network Engineer  
**Topic**: "Distributed systems consensus mechanisms"  
**Duration**: 50 turns (25 per participant)

**Expected Conceptual Attractors**:
- consensus, consistency, partition-tolerance, availability
- raft, paxos, byzantine-fault-tolerance, leader-election
- reliability, performance, trade-offs, CAP-theorem

**Hypothesis**: Expert-level dialogue produces higher-weight, more stable concepts.

**Key Questions**:
- How do complementary expertises consolidate into unified understanding?
- Which concepts prove most stable across different expert perspectives?
- What technical nuances emerge through detailed exploration?

### 4. Relationship Discovery (`relationship-test`)

**Participants**: Evolutionary Biologist vs Senior Developer  
**Topic**: "Apply biological evolution principles to software development"  
**Duration**: 50 turns (25 per participant)

**Expected Conceptual Attractors**:
- natural-selection, mutation, adaptation, evolution
- iteration, refactoring, testing, code-review
- fitness-landscape, genetic-algorithm, selection-pressure

**Hypothesis**: Metaphorical conversations create distinct relationship patterns from literal discussions.

**Key Questions**:
- How do biological metaphors map to software development practices?
- Which analogical relationships prove most valuable for understanding?
- What novel development insights emerge from evolutionary thinking?

## Analysis Tools

### Conceptual Attractors Analysis

```bash
ks conceptual-attractors EXPERIMENT_NAME [--min-rounds N] [--format json|csv|table]
```

Identifies concepts that appear persistently across multiple dialogue rounds, indicating natural conversation focal points.

**Output**: Concept names with appearance frequency, weight evolution, and round spans.

### Relationship Emergence Analysis

```bash
ks relationship-emergence EXPERIMENT_NAME [--min-strength N] [--format json|csv|table]
```

Tracks how concept relationships form and strengthen during conversation, revealing knowledge integration patterns.

**Output**: Relationship pairs with strength evolution, mention frequency, and temporal patterns.

### Knowledge Consolidation Analysis

```bash
ks knowledge-consolidation EXPERIMENT_NAME [--min-mentions N] [--format json|csv|table]
```

Measures concept definition stability and weight evolution, showing how ideas crystallize through dialogue.

**Output**: Concept durability, definition stability, and importance evolution metrics.

## Real-Time Monitoring

### Using ksd

Monitor any running experiment in real-time:

```bash
# Start experiment (terminal 1)
cd experiments/EXPERIMENT_NAME
./run-experiments.sh run EXPERIMENT_NAME

# Monitor progress (terminal 2)
cd experiments/EXPERIMENT_NAME
source .ks-env  # Load experiment environment variables
ksd             # Launch knowledge system dashboard
```

### Key Monitoring Features

- **Event Stream**: Watch conversation events as they occur
- **Concept Formation**: See concepts extracted in real-time
- **Progress Tracking**: Monitor dialogue round progression
- **Quality Assessment**: Observe conversation quality and engagement

## Expected Insights

### For Knowledge Graph Enhancement

1. **Concept Deduplication**: Which concepts are actually the same vs genuinely different?
2. **Relationship Weighting**: How should relationship strength evolve over time?
3. **Cross-Reference Optimization**: Which dialogue moments produce the strongest concepts?
4. **Temporal Patterns**: How do concept weights naturally decay or strengthen?

### For Development Prioritization

- **Consistent Patterns** → Prioritize clustering algorithms
- **Noisy Relationship Discovery** → Focus on better inference methods  
- **Variable Consolidation by Style** → Develop persona-aware processing
- **Valuable Cross-Domain Transfer** → Enhance analogical reasoning

## Integration with Mechanistic Interpretability

Compare experimental results with recent research on concept formation in large language models:

- Do dialogue-emergent concepts match internal model representations?
- Are AI-AI discovered relationships consistent with human intuitions?
- How do conversation-level attractors relate to model-level feature activations?

## Configuration Format

Each experiment uses a `logex-config.yaml` file with this structure:

```yaml
conversation:
  name: "EXPERIMENT_NAME"
  topic: "Research topic"
  description: "Experiment description"

settings:
  max_turns_per_conversant: N
  turn_delay_seconds: 0
  rate_limit_delay: 0

conversants:
  alice:
    type: "claude"
    persona: "Detailed persona description..."
  bob:
    type: "claude" 
    persona: "Detailed persona description..."

dialogue:
  starter: "alice"
  initial_prompt: "Opening conversation prompt..."
  turn_taking:
    strategy: "round_robin"

exit_conditions:
  max_total_turns: N*2
  keywords: ["goodbye", "farewell", "end conversation"]
  manual_stop: true
```

## Advanced Usage

### Batch Execution

```bash
# Run all experiments sequentially
./experiments/run-experiments.sh run

# Check status of all experiments
./experiments/run-experiments.sh status

# Clean experiment data
./experiments/run-experiments.sh clean EXPERIMENT_NAME
```

### Custom Analysis

```bash
# Export data for external analysis
ks conceptual-attractors concept-formation-test --format csv > attractors.csv
ks relationship-emergence relationship-test --format json > relationships.json

# Query knowledge graph directly
cd experiments/EXPERIMENT_NAME
ks kg query --experiment-analysis
```

### Extending Experiments

To create new experiments:

1. Use `tools/logex/configure NEW_EXPERIMENT_NAME`
2. Edit the generated `logex-config.yaml`
3. Add experiment name to `run-experiments.sh` EXPERIMENTS array
4. Run and analyze using existing tools

## Future Enhancements

Based on experimental results, consider:

1. **Multi-turn persona evolution** - How personas adapt during long conversations
2. **Intervention experiments** - Human guidance effects on concept formation
3. **Larger dialogue groups** - 3+ participant conversation dynamics
4. **Domain expertise gradients** - Varying levels of expertise interactions
5. **Conversation style variations** - Collaborative vs adversarial dialogue modes

This experimental framework provides empirical foundation for data-driven development priorities in the knowledge system.