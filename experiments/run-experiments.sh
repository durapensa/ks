#!/usr/bin/env bash

# run-experiments.sh - Run all logex dialogue experiments for conceptual attractor discovery

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KS_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Logex Dialogue Experiments - Conceptual Attractor Discovery"
echo "==========================================================="
echo

# Available experiments
EXPERIMENTS=(
    "scientist-philosopher-emergence"
    "optimist-pessimist-ethics"  
    "specialist-generalist-knowledge"
    "past-future-creativity"
)

# Function to run a single experiment
run_experiment() {
    local experiment_name="$1"
    local experiment_dir="$SCRIPT_DIR/$experiment_name"
    
    echo "Running experiment: $experiment_name"
    echo "-----------------------------------"
    
    if [[ ! -d "$experiment_dir" ]]; then
        echo "Error: Experiment directory not found: $experiment_dir"
        return 1
    fi
    
    # Change to experiment directory
    cd "$experiment_dir"
    
    # Run the orchestrator
    echo "Starting logex orchestration..."
    "$KS_ROOT/tools/logex/orchestrate" "$experiment_name"
    
    # Wait for completion (in real implementation, this would monitor the process)
    echo "Experiment orchestration initiated."
    echo "Monitor progress with: ksd"
    echo
    
    cd "$SCRIPT_DIR"
}

# Function to analyze experiment results
analyze_experiment() {
    local experiment_name="$1"
    
    echo "Analyzing experiment: $experiment_name"
    echo "------------------------------------"
    
    # Run knowledge graph distillation first
    echo "Running knowledge graph distillation..."
    cd "$SCRIPT_DIR/$experiment_name"
    "$KS_ROOT/tools/kg/run-distillation"
    
    # Extract conceptual attractors
    echo "Extracting conceptual attractors..."
    "$KS_ROOT/tools/analyze/extract-conceptual-attractors" "$experiment_name"
    
    echo
    echo "Identifying conversation flows..."
    "$KS_ROOT/tools/analyze/identify-conversation-flows" "$experiment_name"
    
    echo  
    echo "Analyzing relationship patterns..."
    "$KS_ROOT/tools/analyze/analyze-relationship-patterns" "$experiment_name"
    
    echo
    echo "----------------------------------------"
    echo
}

# Main execution
case "${1:-}" in
    "run")
        experiment_name="${2:-}"
        if [[ -n "$experiment_name" ]]; then
            if [[ " ${EXPERIMENTS[*]} " =~ " $experiment_name " ]]; then
                run_experiment "$experiment_name"
            else
                echo "Error: Unknown experiment '$experiment_name'"
                echo "Available experiments: ${EXPERIMENTS[*]}"
                exit 1
            fi
        else
            echo "Running all experiments..."
            for exp in "${EXPERIMENTS[@]}"; do
                run_experiment "$exp"
                sleep 5  # Brief pause between experiments
            done
        fi
        ;;
    "analyze")
        experiment_name="${2:-}"
        if [[ -n "$experiment_name" ]]; then
            if [[ " ${EXPERIMENTS[*]} " =~ " $experiment_name " ]]; then
                analyze_experiment "$experiment_name"
            else
                echo "Error: Unknown experiment '$experiment_name'"
                echo "Available experiments: ${EXPERIMENTS[*]}"
                exit 1
            fi
        else
            echo "Analyzing all experiments..."
            for exp in "${EXPERIMENTS[@]}"; do
                analyze_experiment "$exp"
            done
        fi
        ;;
    "list")
        echo "Available experiments:"
        for exp in "${EXPERIMENTS[@]}"; do
            echo "  - $exp"
        done
        ;;
    "status")
        echo "Experiment Status:"
        echo "=================="
        for exp in "${EXPERIMENTS[@]}"; do
            exp_dir="$SCRIPT_DIR/$exp"
            if [[ -f "$exp_dir/knowledge/kg.db" ]]; then
                concept_count=$(sqlite3 "$exp_dir/knowledge/kg.db" "SELECT COUNT(*) FROM concepts" 2>/dev/null || echo "0")
                echo "  $exp: $concept_count concepts extracted"
            else
                echo "  $exp: Not run yet"
            fi
        done
        ;;
    *)
        echo "Usage: $0 {run|analyze|list|status} [experiment_name]"
        echo
        echo "Commands:"
        echo "  run [experiment]     Run specific experiment or all experiments"
        echo "  analyze [experiment] Analyze specific experiment or all experiments"
        echo "  list                 List available experiments"
        echo "  status               Show status of all experiments"
        echo
        echo "Available experiments:"
        for exp in "${EXPERIMENTS[@]}"; do
            echo "  - $exp"
        done
        ;;
esac