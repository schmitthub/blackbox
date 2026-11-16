# Targets for the Go module in core/. The Makefile in the repository root
# forwards to these, so `make test` there and `make test` here are the same.

.DEFAULT_GOAL := help
.PHONY: help build test test-int test-migrations mocks lint

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

build: ## Build the API binary to bin/api in the repository root
	CGO_ENABLED=0 go build -o ../bin/api ./cmd/api

test: ## Run unit tests
	go test ./...

test-int: ## Run integration tests, on an embedded PostgreSQL
	go test -tags=integration ./...

test-migrations: ## Run the real migrations up, down and up on an embedded PostgreSQL
	scripts/test-migrations.sh

mocks: ## Regenerate mocks from .mockery.yml
	mockery

lint: ## Run golangci-lint
	golangci-lint run --config ../.golangci.yml
