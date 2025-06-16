# Implementation Plan for Issue #24: Logex Dialogue Composer System
*Note: This implementation also solves Issue #1 (conversation test harness) and pilots system-wide supervisord migration*

## Phase 1: Core Infrastructure (2-3 days)

### 1.1 Directory Structure & Session Management
- **Unified conversation directories**: `<conversation-name>/` works for both chat and logex
- **Type identification**: `logex-config.yaml` vs `chat-config.yaml` 
- **Directory creation**: `tools/logex/configure` handles structure creation using `lib/core.sh`
- **File structure**: `knowledge/`, `conversants/`, `supervise/` subdirectories
- **Symlink management**: `tools/` always symlinks back to ks project

### 1.2 Configuration Builder (`tools/logex/configure`)
- **Interactive CLI wizard**: User-friendly YAML builder
- **Real-time validation**: Leverage `lib/validation.sh` patterns for YAML validation
- **Directory creation**: Creates conversation structure in empty folders
- **Conversant naming**: Arbitrary user-defined names (scientist, philosopher, etc.)
- **Metadata capture**: Max turns, timeout, topic, exit conditions
- **Exit strategies**: Turn limits, keyword triggers, manual stop
- **Templates**: Basic 2-party dialogue, expandable for N-way conversations

### 1.3 Process Orchestration (`tools/logex/orchestrate`)
- **Supervisord integration**: Process management for Claude CLI instances
- **Session isolation**: One conversation per directory
- **Turn coordination**: Simple round-robin with configurable delays
- **Context injection**: "Previous speaker said X, now respond"
- **Rate limiting**: Configurable sleep between turns (default 0)
- **Event logging**: Process failures and orchestrator events

### 1.4 Integration Points
- **ks command integration**: `ks logex configure`, `ks logex orchestrate <name>`
- **Argument parsing**: Add LOGEX category to existing system
- **Background monitoring**: New `tools/logex/supervisor` (pilots supervisord migration)
- **Library usage**: Extend `lib/core.sh` for directory management
- **Error handling**: Log crashes, no restart (context unrecoverable)

## Phase 2: Core Features & Test Harness (1-2 days)

### 2.1 Conversation Management
- **Persona injection**: System prompts via Claude CLI context
- **Individual logging**: `conversants/<name>.jsonl` per participant
- **Consolidated events**: `knowledge/` directory for session events
- **Process state**: `supervise/` for supervisord configs and status

### 2.2 Test Harness Implementation (Solves Issue #1)
- **Test scenarios**: `tests/logex/` with YAML test configurations
- **Event validation**: Exit conditions verify expected event creation
- **Performance metrics**: Orchestrator logs timing, API costs
- **Test reports**: Structured output for CI/CD integration
- **Regression testing**: Automated conversation scenarios
- **Integration with existing test framework**: Fast/mocked/e2e patterns

### 2.3 Exit Conditions & Cleanup
- **Multiple triggers**: Turn limits, keyword detection, manual termination
- **Graceful shutdown**: Proper process cleanup via supervisord
- **Session completion**: Status tracking and final event logging

## Phase 3: Polish & Documentation (1 day)

### 3.1 Examples & Templates
- **Working examples**: 2-party dialogue configurations
- **Test scenarios**: Thought capture, multi-event responses, edge cases
- **Documentation**: Usage guide, YAML schema reference
- **Error messaging**: Clear validation and runtime error reporting

### 3.2 Future Work Stubs
- **Turn-taking strategies**: Architecture for pluggable algorithms
- **N-way conversations**: Framework for >2 participants
- **Resume capability**: Notes for future event-based reconstruction

## Key Deliverables:
- `tools/logex/configure` - Interactive YAML builder with directory creation
- `tools/logex/orchestrate` - Headless conversation runner
- `tools/logex/supervisor` - Process monitoring (supervisord pilot)
- Supervisord integration with isolated process management
- Unified conversation directory structure
- Test harness solving Issue #1 requirements
- Working 2-party dialogue examples
- Integration with ks command and existing test framework
- Extended `lib/core.sh` functions for directory management
- YAML validation using `lib/validation.sh` patterns

## Issues Resolved:
- **Issue #24**: Configuration-driven conversation harness
- **Issue #1**: Conversation test harness for automated testing
- **Pilots system-wide supervisord migration** (replacing existing background processing)

## Post-Implementation Tasks:
- Evaluate `lib/validation.sh` for YAML validation applicability
- Create issue for system-wide supervisord migration (if none exists)
- Document supervisord patterns for other background processes

## Architecture Notes:
- **Arbitrary naming**: All conversant names user-defined, no hardcoding
- **Directory isolation**: One conversation per directory prevents cross-contamination
- **Process separation**: Each Claude CLI instance runs independently
- **Event-driven**: All state captured in JSONL event logs
- **Test-ready**: Built-in validation and reporting for automated testing
- **Supervisord foundation**: Establishes pattern for modernizing all background processing
- **Library integration**: Leverages and extends existing core functions