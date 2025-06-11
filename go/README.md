# Go Components

This directory contains Go implementations that complement the bash-based knowledge system.

## Structure

```
go/
├── cmd/                    # Entry points for binaries
│   └── event-viewer/      # Test app for Go integration
├── pkg/                   # Shared packages
│   ├── config/           # .ks-env configuration reader
│   ├── events/           # JSONL event handling
│   └── ui/               # TUI components (future)
├── bin/                  # Built binaries (.gitignored)
├── Makefile              # Build commands
├── go.mod                # Module definition
└── go.sum               # Dependency checksums
```

## Development

```bash
cd go/

# Build test binaries to go/bin/
make build

# Run tests
make test

# Development with hot reload (requires air)
make dev

# Clean build artifacts
make clean
```

## Build Strategy

- Test/development binaries: Built to `go/bin/`
- User-facing binaries (like future `ksd-tui`): Built to project root

The `ksd` bash script remains untouched. When ready, we'll build `ksd-tui` as a Go replacement.

## Integration

Go code respects the `.ks-env` configuration and integrates seamlessly with existing bash tools.

## Testing the Integration

```bash
cd go
make build
./bin/event-viewer  # Test app to view events (requires TTY)
```

## Future Components

- **ksd-tui**: Bubbletea-based dashboard replacing the current `ksd` script
- **ks-graph**: SQLite-based knowledge graph for advanced queries
- **ks-stream**: Real-time event processing and pattern detection