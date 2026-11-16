# Repository-wide targets. The Go module's targets are in core/Makefile:
# make -C core <target>.
COMPOSE := docker compose --env-file .env -f deploy/compose.yaml -f deploy/compose.override.yaml

.DEFAULT_GOAL := help
.PHONY: help check image up down reset logs ps

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

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
