COMPOSE := docker compose --env-file .env -f deploy/compose.yaml -f deploy/compose.override.yaml

.DEFAULT_GOAL := help
.PHONY: help build test test-int test-migrations mocks lint check image up down reset logs ps

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

build: ## Build the API binary to bin/api
	CGO_ENABLED=0 go -C core build -o ../bin/api ./cmd/api

test: ## Run unit tests
	go -C core test ./...

test-int: ## Run integration tests, on an embedded PostgreSQL
	go -C core test -tags=integration ./...

test-migrations: ## Run the real migrations up, down and up on a throwaway database
	core/scripts/test-migrations.sh

mocks: ## Regenerate mocks from core/.mockery.yml
	cd core && mockery

lint: ## Run golangci-lint
	cd core && golangci-lint run --config ../.golangci.yml

check: ## Run every prek hook on all files
	prek run --all-files

image: ## Build the container images
	$(COMPOSE) build

up: ## Build and start the stack, wait until healthy
	$(COMPOSE) up --build -d --wait

down: ## Stop the stack, keep the database volume
	$(COMPOSE) down

reset: ## Stop the stack and DELETE the database volume
	$(COMPOSE) down -v

logs: ## Follow stack logs
	$(COMPOSE) logs -f

ps: ## Show stack status
	$(COMPOSE) ps -a
