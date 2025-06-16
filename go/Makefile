.PHONY: build test clean dev lint install-tools

# Default target
all: build

# Build all binaries
build:
	@echo "Building binaries..."
	@mkdir -p bin
	@go build -o bin/event-viewer ./cmd/event-viewer
	@go build -o bin/ksd ./cmd/ksd
	@echo "Built to go/bin/"

# Install ksd to project root (replacing bash version)
install-ksd:
	@echo "Installing new TUI ksd..."
	@go build -o bin/ksd ./cmd/ksd
	@cp ../ksd ../ksd-legacy
	@cp bin/ksd ../ksd
	@echo "New TUI ksd installed (legacy version saved as ksd-legacy)"

# Run tests
test:
	@echo "Running tests..."
	@go test -v ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@go test -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html
	@rm -rf tmp/

# Development mode with hot reload (requires air)
dev:
	@if command -v air > /dev/null; then \
		air; \
	else \
		echo "Air not installed. Install with: go install github.com/cosmtrek/air@latest"; \
		exit 1; \
	fi

# Run linter (requires golangci-lint)
lint:
	@if command -v golangci-lint > /dev/null; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed. Install with: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin"; \
	fi

# Install development tools
install-tools:
	@echo "Installing development tools..."
	@go install github.com/cosmtrek/air@latest
	@echo "For golangci-lint, run: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin"

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...