# Logex Dialogue Experiments

This directory contains Claude-Claude dialogue experiments designed to discover conceptual attractors as described in GitHub issue #20.

## Overview

The experiments explore how extended AI-AI dialogue reveals persistent conceptual structures through systematic analysis of conversation patterns. Each experiment features two Claude instances with different personas engaging in extended dialogue about specific topics.

## Available Experiments

### 1. Scientist vs Philosopher - Emergence and Complexity
- **Directory**: `scientist-philosopher-emergence/`
- **Personas**: Reductionist scientist vs Holistic philosopher
- **Topic**: How emergent properties arise in complex systems
- **Style**: Dialectical opposition
- **Expected Attractors**: consciousness, reductionism, causation, emergence, complexity

### 2. Optimist vs Pessimist - Ethics and Evolution
- **Directory**: `optimist-pessimist-ethics/`
- **Personas**: Optimistic vs Pessimistic views on human nature
- **Topic**: How moral systems emerge from evolutionary pressures
- **Style**: Dialectical opposition
- **Expected Attractors**: altruism, selfishness, cooperation, competition, moral_progress

### 3. Specialist vs Generalist - Knowledge and Uncertainty
- **Directory**: `specialist-generalist-knowledge/`
- **Personas**: Deep specialist vs Broad generalist
- **Topic**: Nature of knowledge and relationship with uncertainty
- **Style**: Collaborative building
- **Expected Attractors**: expertise, synthesis, uncertainty, complexity, patterns

### 4. Past vs Future - Creativity and Constraints
- **Directory**: `past-future-creativity/`
- **Personas**: Traditionalist vs Futurist
- **Topic**: How constraints shape and enable creativity
- **Style**: Collaborative building
- **Expected Attractors**: tradition, innovation, constraints, freedom, creativity

## Running Experiments

### Quick Start

```bash
# Run all experiments
./experiments/run-experiments.sh run

# Run specific experiment
./experiments/run-experiments.sh run scientist-philosopher-emergence

# Check status
./experiments/run-experiments.sh status

# Analyze results
./experiments/run-experiments.sh analyze scientist-philosopher-emergence
```

### Manual Execution

```bash
# Run specific experiment manually
cd experiments/scientist-philosopher-emergence
ks logex orchestrate scientist-philosopher-emergence

# Monitor progress
ksd  # In separate terminal

# Analyze results after completion
ks kg run-distillation
ks extract-conceptual-attractors scientist-philosopher-emergence
ks identify-conversation-flows scientist-philosopher-emergence
ks analyze-relationship-patterns scientist-philosopher-emergence
```

## Analysis Tools

### 1. Extract Conceptual Attractors
Identifies concepts that appear persistently across dialogue rounds.

```bash
ks extract-conceptual-attractors <experiment_name>
```

**Output**: Concepts with their occurrence frequency across rounds, total mentions, and average weights.

### 2. Identify Conversation Flows
Finds concepts that conversations naturally flow toward (high inbound connections).

```bash
ks identify-conversation-flows <experiment_name>
```

**Output**: Concepts with high inflow counts, showing which ideas serve as focal points.

### 3. Analyze Relationship Patterns
Discovers relationships that strengthen over time during dialogue.

```bash
ks analyze-relationship-patterns <experiment_name>
```

**Output**: Concept pairs with strengthening connections, showing emergent associations.

### 4. Knowledge Graph Query
Provides experiment-specific analysis and statistics.

```bash
ks kg query --experiment <experiment_name>
```

**Output**: Overview of experiment data, timelines, and relationship distributions.

## Configuration Structure

Each experiment directory contains:

```
experiment-name/
├── logex-config.yaml       # Experiment configuration
├── conversants/            # Individual conversant logs
├── knowledge/              # Knowledge capture
│   ├── events/
│   │   └── hot.jsonl      # Event stream
│   └── kg.db              # Knowledge graph (after distillation)
└── supervise/             # Process supervision
```

### Configuration Format

```yaml
conversation:
  name: "experiment-name"
  topic: "discussion topic"
  description: "Experiment description"

settings:
  max_turns_per_conversant: 50
  turn_delay_seconds: 2
  rate_limit_delay: 1000

conversants:
  persona_a:
    type: "claude"
    persona: "Detailed persona description..."
  persona_b:
    type: "claude"
    persona: "Detailed persona description..."

dialogue:
  starter: "persona_a"
  initial_prompt: "Opening prompt to start conversation..."
  turn_taking:
    strategy: "round_robin"

exit_conditions:
  max_total_turns: 100
  keywords: ["conclusion", "synthesis", "endpoint"]
  manual_stop: true

experimental:
  experiment_type: "conceptual_attractor_discovery"
  persona_pair: "scientist_philosopher"
  topic_seed: "emergence_complexity"
  conversation_style: "dialectical_opposition"
  expected_attractors: ["concept1", "concept2", "..."]
```

## Expected Outcomes

### Conceptual Attractors
- **Universal Attractors**: Concepts that emerge regardless of starting point
- **Persona-Specific Patterns**: Ideas that consistently appear with certain persona combinations
- **Topic-Driven Emergence**: Concepts that naturally arise from specific discussion domains

### Relationship Patterns
- **Strengthening Associations**: Concept pairs that become more strongly connected over time
- **Bridge Concepts**: Ideas that consistently link disparate domains
- **Emergent Hierarchies**: How abstract concepts emerge from concrete discussions

### Validation Opportunities
- **Mechanistic Interpretability**: Compare discovered attractors with published findings about LLM features
- **Predictive Testing**: Use identified patterns to predict concept emergence in new dialogues
- **Cross-Validation**: Verify patterns across different persona combinations and topics

## Monitoring and Debugging

### Real-time Monitoring
```bash
# Watch experiment progress
ksd

# Check logs
tail -f experiments/<experiment>/conversants/*.log
tail -f experiments/<experiment>/supervise/*.log
```

### Troubleshooting
```bash
# Validate configuration
ks logex configure --dry-run --output <experiment>

# Check orchestration status
ks logex orchestrate --status

# Verify event capture
head experiments/<experiment>/knowledge/events/hot.jsonl
```

## Integration with Research

### Mechanistic Interpretability Connections
- Compare discovered attractors with known LLM features
- Validate hierarchical patterns against attention head specialization
- Test predictions about concept emergence

### Experimental Methodology
- Use control experiments with identical persona pairs
- Vary conversation styles while keeping personas constant
- Test robustness across different topic seeds

### Data Export
```bash
# Export for external analysis
ks extract-conceptual-attractors <experiment> --format json > attractors.json
ks identify-conversation-flows <experiment> --format csv > flows.csv
ks analyze-relationship-patterns <experiment> --format json > patterns.json
```

## Future Extensions

### Additional Persona Pairs
- Expert vs Novice
- Intuitive vs Analytical
- Collaborative vs Competitive
- Creative vs Practical

### Conversation Styles
- Socratic questioning
- Free association
- Structured debate
- Exploratory dialogue

### Analysis Enhancements
- Temporal evolution tracking
- Concept clustering algorithms
- Cross-experiment pattern detection
- Predictive modeling

This framework provides a solid foundation for discovering conceptual attractors through systematic AI-AI dialogue analysis, with clear pathways for validation against mechanistic interpretability research.