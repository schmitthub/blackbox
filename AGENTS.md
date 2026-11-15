# Blackbox

Blackbox records what goes into the body and what comes out of it as timeseries events, so the relationships between them can be queried. It is a Go API (Gin) on PostgreSQL, run with Docker Compose.

## Shared instructions

Claude Code and Codex use the same project instructions and skills.

- Store instructions in regular `AGENTS.md` files. Each must have a sibling `CLAUDE.md` symbolic link with the relative target `AGENTS.md`.
- A requirement for one package tree lives in that tree's `AGENTS.md`. Read the `AGENTS.md` files along the path to each file you change.
- Shared skills live in `.agents/skills/`, one `SKILL.md` per skill directory. `.claude/skills` links to it; Codex discovers it directly.
- Keep `.agents/` independent of any harness. Native settings and tool-specific hooks stay in `.claude/` or `.codex/`. Never link from `.agents/` into either.
- Shared command guards live in `.agents/hooks/`. Both `.claude/settings.json` and `.codex/config.toml` register them. The Codex hooks use inline TOML; do not add `.codex/hooks.json`, or each guard registers twice.
- Symbolic links under `.agents/`, `.claude/` and `.codex/` are relative and stay inside the repository.

The `agent-compat` commit hook and the CI job `Agent compatibility` run `scripts/check-agent-compatibility.py`, which enforces the layout above. CI also runs its tests, `scripts/test_agent_compatibility.py`.

## Layout

- `cmd/api/`: the binary. It only wires config, the database pool, the router and the server.
- `internal/config/`: configuration from the environment.
- `internal/api/`: HTTP routes and handlers.
- `internal/server/`: HTTP server lifecycle.
- `migrations/`: goose migrations.
- `deploy/`: Compose files and one subdirectory per service.

## Commands

- `make help` lists every target.
- `make test`, `make lint`: unit tests and golangci-lint.
- `make check`: every commit hook on all files.
- `make up`, `make down`, `make reset`: the Compose stack. `make reset` deletes the database volume.

## Rules

- Every commit goes through the prek hooks. The `git-checks` guard blocks `--no-verify` and the other ways around them.
- Commits must be signed. `main` only takes squash merges from pull requests.
- CI workflow and scanner versions are pinned; keep the versions in `prek.toml` and `.github/workflows/ci.yml` in step.
