# Phase 2 Development Notes - Logex System

## Current State (Phase 1 Complete)

### ✅ Implemented Components
- **Configuration Builder** (`tools/logex/configure`) - Working, creates YAML configs and directory structures
- **Process Orchestration** (`tools/logex/orchestrate`) - Configuration parsing and supervisord config generation
- **Process Monitoring** (`tools/logex/supervisor`) - Process discovery, listing, status monitoring
- **Core Libraries** - Extended `lib/core.sh` and `lib/categories.sh` for logex support
- **Test Framework** - Basic test structure and example configurations
- **ks Integration** - All tools auto-discovered and available via ks subcommands

### 🔧 Known Minor Issues
- Configure tool returns exit code 1 despite successful operation (functional but affects tests)
- Tests need refinement for exit code handling
- YAML parsing uses basic sed/grep (works but could be enhanced)

## Phase 2 Priority Tasks

### 1. Orchestrator Worker Process (High Priority)
**File**: `tools/logex/orchestrate-worker`
- **Purpose**: The actual conversation conductor that runs under supervisord
- **Responsibilities**:
  - Parse configuration and initialize conversants
  - Manage Claude CLI processes via supervisord
  - Implement turn-taking logic (start with simple round-robin)
  - Inject context between turns ("Previous speaker said X...")
  - Monitor exit conditions (turn limits, keywords, manual stop)
  - Handle process failures and cleanup
- **Integration**: Called by supervisord config created by `orchestrate` tool

### 2. Claude CLI Process Management
**Location**: `tools/logex/` helper scripts
- **claude-instance**: Wrapper script for individual Claude processes
- **Responsibilities**:
  - Set up isolated conversation context for each conversant
  - Inject persona prompts into Claude CLI
  - Capture responses to conversant-specific log files
  - Handle graceful shutdown on orchestrator signals

### 3. Turn Coordination System
**Enhancement**: Extend orchestrate-worker
- **Simple Round-Robin**: Start with fixed alternating turns
- **Context Injection**: Pass previous utterances to next speaker
- **Exit Detection**: Monitor for keyword triggers and turn limits
- **Event Logging**: Capture all orchestrator decisions and state changes

### 4. Test Integration (Medium Priority)
**Enhancement**: Complete test harness capability (Issue #1)
- **Mock Mode**: Run conversations without actual Claude API calls
- **Assertion System**: Validate expected events, turn counts, etc.
- **Test Reports**: Structured output for CI/CD integration
- **Example Tests**: Working test scenarios in `tests/logex/`

### 5. Process Management Polish (Low Priority)
**Enhancement**: Improve supervisord integration
- **Error Recovery**: Better handling of Claude CLI crashes
- **Logging**: Structured logs for debugging
- **Status API**: Rich status information for monitoring
- **Graceful Shutdown**: Clean process termination

## Technical Architecture Notes

### Directory Structure (Established)
```
<conversation-name>/
├── logex-config.yaml          # Configuration
├── knowledge/                 # Consolidated events
├── conversants/               # Individual logs (alice.jsonl, bob.jsonl, etc.)
│   ├── alice.log             # Claude CLI output
│   └── bob.log               # Claude CLI output  
└── supervise/                # Process management
    ├── supervisord.conf      # Generated config
    ├── supervisord.log       # Supervisor logs
    └── orchestrator.log      # Worker process logs
```

### Process Hierarchy (Planned)
```
supervisord
├── orchestrator              # Main coordination logic
├── claude-alice              # Claude CLI for alice persona
└── claude-bob                # Claude CLI for bob persona
```

### Configuration Schema (Working)
```yaml
conversation:
  name: "dialogue-name"
  topic: "discussion topic"
  
conversants:
  alice:
    type: "claude"
    persona: "System prompt here"
    
dialogue:
  starter: "alice"
  initial_prompt: "Opening message"
  turn_taking:
    strategy: "round_robin"
    
exit_conditions:
  max_total_turns: 10
  keywords: ["goodbye", "farewell"]
```

## Development Workflow

### Quick Start for Phase 2
1. **Test Current System**: `ks configure --template simple --output test-phase2`
2. **Examine Generated Config**: `cat test-phase2/logex-config.yaml`
3. **Check Supervisord Config**: `ks orchestrate test-phase2 && cat test-phase2/supervise/supervisord.conf`
4. **Start with Worker**: Implement `tools/logex/orchestrate-worker` script

### Key Design Principles
- **Fail Fast**: Clear error messages and validation
- **Observable**: Rich logging and status information  
- **Testable**: Mock modes and assertion capabilities
- **Extensible**: Architecture supports future enhancements
- **Isolated**: Each conversation in separate directory/process space

## Future Considerations (Post-Phase 2)
- **N-way Conversations**: Support for >2 participants
- **Advanced Turn-Taking**: Moderated, topic-driven, etc.
- **Resume Capability**: Restart conversations from event logs
- **Web Interface**: TUI/web dashboard for conversation monitoring
- **Model Flexibility**: Support for other AI models beyond Claude
- **Performance Optimization**: Concurrent conversations, resource limits

## Issues & Dependencies
- **Issue #29**: System-wide supervisord migration (logex is pilot)
- **supervisord**: Required dependency, installed via Homebrew
- **claude CLI**: Required for conversation execution
- **bats**: Test framework for automated testing

---
*Created: 2025-06-16*
*Next Update: After Phase 2 completion*