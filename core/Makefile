# Targets for the Go module. Run them in core/, or from the repository root
# with make -C core <target>.

.DEFAULT_GOAL := help
.PHONY: help build test test-int test-migrations mocks check-mocks lint

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

build: ## Build the API binary to bin/api
	CGO_ENABLED=0 go build -o bin/api ./cmd/api

test: ## Run unit tests
	go test ./...

test-int: ## Run integration tests, on an embedded PostgreSQL
	go test -tags=integration ./...

test-migrations: ## Run the real migrations up, down and up on an embedded PostgreSQL
	scripts/test-migrations.sh

mocks: ## Regenerate mocks from .mockery.yml
	mockery

check-mocks: mocks ## Fail when the committed mocks are out of date
	git diff --exit-code -- ':(glob)**/mocks/**'

lint: ## Run golangci-lint
	golangci-lint run --config .golangci.yml
