# Targets for the MCP server module. Run them in mcp/, or from the
# repository root with make -C mcp <target>.

.DEFAULT_GOAL := help
.PHONY: help build test lint

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

build: ## Build the MCP server binary to bin/mcp
	CGO_ENABLED=0 go build -o bin/mcp ./cmd/mcp

test: ## Run unit tests
	go test ./...

lint: ## Run golangci-lint
	golangci-lint run --config .golangci.yml
