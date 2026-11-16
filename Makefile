COMPOSE := docker compose --env-file .env -f deploy/compose.yaml -f deploy/compose.override.yaml
CORE_TARGETS := build test test-int test-migrations mocks lint

.DEFAULT_GOAL := help
.PHONY: help check image up down reset logs ps $(CORE_TARGETS)

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'
	@$(MAKE) -s -C core help | grep -v "List targets"

# The Go module's targets live in core/Makefile.
$(CORE_TARGETS):
	@$(MAKE) -C core $@

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
