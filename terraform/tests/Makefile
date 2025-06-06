# Terraform Testing Makefile

# Default AWS region for tests
AWS_REGION ?= us-east-1

# Test timeout (in minutes)
TEST_TIMEOUT ?= 30

# Go test flags
GO_TEST_FLAGS ?= -v -timeout $(TEST_TIMEOUT)m

.PHONY: help
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: deps
deps: ## Install Go dependencies
	go mod download
	go mod tidy

.PHONY: test-unit
test-unit: ## Run unit tests for individual modules
	@echo "Running unit tests for Terraform modules..."
	cd modules && go test $(GO_TEST_FLAGS) ./...

.PHONY: test-networking
test-networking: ## Run tests for networking module only
	@echo "Running networking module tests..."
	cd modules && go test $(GO_TEST_FLAGS) -run TestNetworking ./...

.PHONY: test-compute
test-compute: ## Run tests for compute module only
	@echo "Running compute module tests..."
	cd modules && go test $(GO_TEST_FLAGS) -run TestCompute ./...

.PHONY: test-security
test-security: ## Run tests for security module only
	@echo "Running security module tests..."
	cd modules && go test $(GO_TEST_FLAGS) -run TestSecurity ./...

.PHONY: test-database
test-database: ## Run tests for database module only
	@echo "Running database module tests..."
	cd modules && go test $(GO_TEST_FLAGS) -run TestDatabase ./...

.PHONY: test-integration
test-integration: ## Run integration tests for complete infrastructure
	@echo "Running integration tests..."
	cd integration && go test $(GO_TEST_FLAGS) ./...

.PHONY: test-integration-short
test-integration-short: ## Run integration tests with simplified scenarios
	@echo "Running short integration tests..."
	cd integration && go test $(GO_TEST_FLAGS) -short ./...

.PHONY: test-all
test-all: test-unit test-integration ## Run all tests

.PHONY: test-all-short
test-all-short: ## Run all tests in short mode (skips AWS resource creation)
	@echo "Running all tests in short mode..."
	go test $(GO_TEST_FLAGS) -short ./...

.PHONY: validate
validate: ## Validate Terraform configurations
	@echo "Validating Terraform configurations..."
	cd .. && terraform init -backend=false
	cd .. && terraform validate

.PHONY: fmt-check
fmt-check: ## Check Go code formatting
	@echo "Checking Go code formatting..."
	gofmt -l .
	@if [ -n "$$(gofmt -l .)" ]; then \
		echo "Go code is not formatted. Run 'make fmt' to fix."; \
		exit 1; \
	fi

.PHONY: fmt
fmt: ## Format Go code
	@echo "Formatting Go code..."
	gofmt -w .

.PHONY: lint
lint: ## Run comprehensive Go linting
	@echo "Running comprehensive Go linting..."
	@echo "1. Checking Go formatting..."
	@gofmt -l . || (echo "Code formatting issues found. Run 'make fmt' to fix." && exit 1)
	@echo "2. Running go vet..."
	@go vet ./...
	@echo "3. Running staticcheck..."
	@if command -v staticcheck > /dev/null 2>&1; then \
		staticcheck ./...; \
	else \
		echo "Installing staticcheck..."; \
		go install honnef.co/go/tools/cmd/staticcheck@latest; \
		staticcheck ./...; \
	fi
	@echo "4. Running golangci-lint..."
	@if command -v golangci-lint > /dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "Installing golangci-lint..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
		golangci-lint run; \
	fi
	@echo "5. Checking for ineffective assignments..."
	@if command -v ineffassign > /dev/null 2>&1; then \
		ineffassign ./...; \
	else \
		echo "Installing ineffassign..."; \
		go install github.com/gordonklaus/ineffassign@latest; \
		ineffassign ./...; \
	fi
	@echo "6. Checking for misspellings..."
	@if command -v misspell > /dev/null 2>&1; then \
		misspell -error .; \
	else \
		echo "Installing misspell..."; \
		go install github.com/client9/misspell/cmd/misspell@latest; \
		misspell -error .; \
	fi
	@echo "7. Running security scan..."
	@if command -v gosec > /dev/null 2>&1; then \
		gosec -quiet ./... || echo "Security findings detected - please review"; \
	else \
		echo "Installing gosec..."; \
		go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest; \
		gosec -quiet ./... || echo "Security findings detected - please review"; \
	fi
	@echo "✅ All Go linting completed!"

.PHONY: lint-quick
lint-quick: ## Run basic Go linting (faster)
	@echo "Running quick Go linting..."
	@gofmt -l . || (echo "Code formatting issues found." && exit 1)
	@go vet ./...
	@if command -v golangci-lint > /dev/null 2>&1; then \
		golangci-lint run --fast; \
	else \
		echo "golangci-lint not installed. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi

.PHONY: clean
clean: ## Clean test artifacts and Terraform state
	@echo "Cleaning test artifacts..."
	find . -name "*.log" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "terraform.tfstate*" -delete 2>/dev/null || true

.PHONY: setup-aws
setup-aws: ## Setup AWS credentials and region for testing
	@echo "Current AWS configuration:"
	@aws sts get-caller-identity || echo "AWS credentials not configured"
	@echo "AWS Region: $(AWS_REGION)"
	@echo ""
	@echo "To configure AWS credentials:"
	@echo "  aws configure"
	@echo "  export AWS_REGION=$(AWS_REGION)"

.PHONY: pre-commit
pre-commit: validate fmt-check lint ## Run pre-commit checks

# Example usage targets
.PHONY: example-unit
example-unit: ## Example: Run a specific unit test
	@echo "Example: Running networking module VPC creation test..."
	cd modules && go test -v -run TestNetworkingModuleCreatesVPCAndSubnets ./...

.PHONY: example-integration
example-integration: ## Example: Run full stack deployment test
	@echo "Example: Running full stack deployment test..."
	cd integration && go test -v -run TestFullStackDeploymentWithoutSSR ./...

# CI/CD targets
.PHONY: ci-test
ci-test: deps validate fmt-check test-all-short ## Run tests suitable for CI (no AWS resources)

.PHONY: cd-test
cd-test: deps validate test-all ## Run comprehensive tests for CD pipeline

# Development targets
.PHONY: dev-setup
dev-setup: deps setup-aws ## Setup development environment
	@echo "Development environment ready!"
	@echo "Try running: make test-unit"

.PHONY: watch
watch: ## Watch for changes and run tests (requires entr)
	@if command -v entr > /dev/null 2>&1; then \
		find . -name "*.go" | entr -c make test-unit; \
	else \
		echo "entr not installed. Install with your package manager."; \
		echo "Example: brew install entr"; \
	fi