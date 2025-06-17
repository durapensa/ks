#!/usr/bin/env bash

# run-experiments.sh - Orchestrate logex experiments for Issue #20

set -euo pipefail

# Source environment
source "$(dirname "${BASH_SOURCE[0]}")/../.ks-env" || exit 1
source "$KS_ROOT/lib/core.sh"
source "$KS_ROOT/lib/error.sh"

EXPERIMENTS=(
    "concept-formation-test"
    "knowledge-transfer-test" 
    "consolidation-test"
    "relationship-test"
)

usage() {
    cat << EOF
Usage: $0 COMMAND [EXPERIMENT_NAME]

Commands:
  run [EXPERIMENT]     Run experiment(s) - all if no name provided
  analyze EXPERIMENT   Run all analysis tools on completed experiment
  status [EXPERIMENT]  Show experiment status - all if no name provided
  list                 List all available experiments
  clean EXPERIMENT     Clean experiment data (removes knowledge/)

Examples:
  $0 run                           # Run all experiments sequentially
  $0 run concept-formation-test    # Run specific experiment
  $0 analyze concept-formation-test # Analyze completed experiment
  $0 status                        # Show status of all experiments

Monitoring:
  To monitor experiment in real-time, open second terminal:
    cd experiments/EXPERIMENT_NAME
    source .ks-env
    ksd

EOF
}

validate_experiment() {
    local experiment="$1"
    local found=false
    
    for exp in "${EXPERIMENTS[@]}"; do
        if [[ "$exp" == "$experiment" ]]; then
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        ks_exit_error "Unknown experiment: $experiment. Available: ${EXPERIMENTS[*]}"
    fi
}

experiment_status() {
    local experiment="$1"
    local exp_dir="$KS_EXPERIMENTS_DIR/$experiment"
    
    if [[ ! -d "$exp_dir" ]]; then
        echo "[X] $experiment: Not configured"
        return
    fi
    
    local config_file="$exp_dir/$KS_CONVERSATION_CONFIG"
    local hot_log="$exp_dir/$KS_CONVERSATION_HOT_LOG"
    local kg_db="$exp_dir/$KS_CONVERSATION_KNOWLEDGE_DIR/concepts.db"
    
    printf "%-25s" "$experiment:"
    
    if [[ ! -f "$config_file" ]]; then
        echo "[X] No config"
    elif [[ ! -f "$hot_log" ]]; then
        echo "[ ] Configured, not started"
    elif [[ ! -f "$kg_db" ]]; then
        local event_count=$(wc -l < "$hot_log" 2>/dev/null || echo "0")
        echo "[~] Running ($event_count events, no KG)"
    else
        local event_count=$(wc -l < "$hot_log" 2>/dev/null || echo "0")
        local concept_count=$(sqlite3 "$kg_db" "SELECT COUNT(*) FROM concepts;" 2>/dev/null || echo "0")
        echo "[*] Complete ($event_count events, $concept_count concepts)"
    fi
}

run_experiment() {
    local experiment="$1"
    local exp_dir="$KS_EXPERIMENTS_DIR/$experiment"
    
    echo "Starting experiment: $experiment"
    echo "Directory: $exp_dir"
    echo ""
    
    # Ensure required directory structure and files exist for ksd monitoring
    mkdir -p "$exp_dir/$KS_CONVERSATION_KNOWLEDGE_DIR/events"
    mkdir -p "$exp_dir/supervise"
    touch "$exp_dir/$KS_CONVERSATION_HOT_LOG"
    touch "$exp_dir/$KS_CONVERSATION_ORCHESTRATION_LOG"
    
    # Show experiment parameters
    local config_file="$exp_dir/$KS_CONVERSATION_CONFIG"
    if [[ -f "$config_file" ]]; then
        local max_turns=$(grep "max_turns_per_conversant:" "$config_file" | sed 's/.*: *//')
        local total_turns=$((max_turns * 2))
        local topic=$(grep "topic:" "$config_file" | sed 's/.*topic: *"\([^"]*\)".*/\1/')
        local alice_persona=$(grep -A1 "alice:" "$config_file" | grep "persona:" | sed 's/.*persona: *"\([^"]*\)".*/\1/' | head -c 60)
        local bob_persona=$(grep -A1 "bob:" "$config_file" | grep "persona:" | sed 's/.*persona: *"\([^"]*\)".*/\1/' | head -c 60)
        
        echo "Experiment Parameters:"
        echo "   Topic: $topic"
        echo "   Turns: $max_turns per conversant ($total_turns total)"
        echo "   Alice: ${alice_persona}..."
        echo "   Bob: ${bob_persona}..."
        echo ""
    fi
    
    echo "To monitor in real-time, open second terminal and run:"
    echo "   cd $exp_dir"
    echo "   source .ks-env"
    echo "   ksd"
    echo ""
    echo "Press Enter to start experiment, Ctrl+C to cancel..."
    read -r
    
    cd "$exp_dir"
    bash "$KS_ROOT/tools/logex/orchestrate-worker" "$exp_dir"
    
    echo ""
    echo "Experiment completed: $experiment"
    echo "Running knowledge graph distillation..."
    
    # Run knowledge graph distillation
    cd "$exp_dir"
    bash "$KS_ROOT/tools/kg/run-distillation"
    
    echo "Experiment ready for analysis. Run:"
    echo "   $0 analyze $experiment"
}

analyze_experiment() {
    local experiment="$1"
    local exp_dir="$KS_EXPERIMENTS_DIR/$experiment"
    
    if [[ ! -d "$exp_dir" ]]; then
        ks_exit_error "Experiment not found: $experiment"
    fi
    
    local kg_db="$exp_dir/$KS_CONVERSATION_KNOWLEDGE_DIR/concepts.db"
    if [[ ! -f "$kg_db" ]]; then
        echo "Knowledge graph not found. Running distillation first..."
        cd "$exp_dir"
        bash "$KS_ROOT/tools/kg/run-distillation"
    fi
    
    echo "Analyzing experiment: $experiment"
    echo ""
    
    echo "Conceptual Attractors:"
    bash "$KS_ROOT/tools/analyze/conceptual-attractors" "$experiment" --verbose
    echo ""
    
    echo "Relationship Emergence:"
    bash "$KS_ROOT/tools/analyze/relationship-emergence" "$experiment" --verbose
    echo ""
    
    echo "Knowledge Consolidation:"
    bash "$KS_ROOT/tools/analyze/knowledge-consolidation" "$experiment" --verbose
    echo ""
    
    echo "Analysis complete for: $experiment"
}

clean_experiment() {
    local experiment="$1"
    local exp_dir="$KS_EXPERIMENTS_DIR/$experiment"
    
    if [[ ! -d "$exp_dir" ]]; then
        ks_exit_error "Experiment not found: $experiment"
    fi
    
    echo "This will delete all experiment data for: $experiment"
    echo "Directory: $exp_dir/knowledge/"
    echo ""
    echo "Type 'yes' to confirm:"
    read -r confirmation
    
    if [[ "$confirmation" == "yes" ]]; then
        # Remove experiment data but preserve directory structure for ksd
        rm -rf "$exp_dir/$KS_CONVERSATION_KNOWLEDGE_DIR"
        rm -f "$exp_dir/supervise/orchestration.jsonl"
        
        # Recreate structure for ksd monitoring
        mkdir -p "$exp_dir/$KS_CONVERSATION_KNOWLEDGE_DIR/events"
        mkdir -p "$exp_dir/supervise"
        touch "$exp_dir/$KS_CONVERSATION_HOT_LOG"
        touch "$exp_dir/$KS_CONVERSATION_ORCHESTRATION_LOG"
        
        echo "Cleaned experiment data: $experiment"
    else
        echo "Clean cancelled"
    fi
}

# Main command handling
case "${1:-}" in
    "run")
        if [[ $# -eq 1 ]]; then
            # Run all experiments
            echo "Running all experiments sequentially..."
            for experiment in "${EXPERIMENTS[@]}"; do
                echo ""
                echo "========================================"
                run_experiment "$experiment"
            done
            echo ""
            echo "All experiments completed!"
        elif [[ $# -eq 2 ]]; then
            # Run specific experiment
            validate_experiment "$2"
            run_experiment "$2"
        else
            ks_exit_error "Usage: $0 run [EXPERIMENT_NAME]"
        fi
        ;;
    "analyze")
        if [[ $# -ne 2 ]]; then
            ks_exit_error "Usage: $0 analyze EXPERIMENT_NAME"
        fi
        validate_experiment "$2"
        analyze_experiment "$2"
        ;;
    "status")
        if [[ $# -eq 1 ]]; then
            # Show all experiments
            echo "Experiment Status:"
            echo ""
            for experiment in "${EXPERIMENTS[@]}"; do
                experiment_status "$experiment"
            done
        elif [[ $# -eq 2 ]]; then
            # Show specific experiment
            validate_experiment "$2"
            experiment_status "$2"
        else
            ks_exit_error "Usage: $0 status [EXPERIMENT_NAME]"
        fi
        ;;
    "list")
        echo "Available experiments:"
        for experiment in "${EXPERIMENTS[@]}"; do
            echo "  - $experiment"
        done
        ;;
    "clean")
        if [[ $# -ne 2 ]]; then
            ks_exit_error "Usage: $0 clean EXPERIMENT_NAME"
        fi
        validate_experiment "$2"
        clean_experiment "$2"
        ;;
    "help"|"--help"|"-h"|"")
        usage
        ;;
    *)
        ks_exit_error "Unknown command: $1"
        ;;
esac