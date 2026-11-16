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

Copilot code review reads `.github/copilot-instructions.md` and the procedure in `.github/skills/code-review/SKILL.md`. Both point at the rules in this file; add a rule here, not there.

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
- `make mocks`: regenerate the mocks listed in `.mockery.yml`. Add an interface there; never edit or hand-write a mock.
- `make check`: every commit hook on all files.
- `make up`, `make down`, `make reset`: the Compose stack. `make reset` deletes the database volume.

## Data rules

- Identity comes from Auth0. The API validates the Auth0 token and maps its subject to a row in `users`. Write no token, password, session or API key check here. Only `/healthz` is public.
- Every row in `inputs`, `outputs` and `events` belongs to one user. Every query restricts rows to the `user_id` of the validated token, never to one taken from the request.
- Queries use placeholders. Never build SQL from request data.
- `events` is append-only. No `UPDATE` or `DELETE` on it.
- All times are stored in UTC, in `timestamptz` columns.
- Inputs and outputs relate only through events and time. Nothing stores that an input causes an output.
- A new attribute starts in `attrs` (jsonb). It earns a column, through a migration, when it is queried on regularly.
- A schema change is a new goose migration with `Up` and `Down`. Never edit a migration that is on `main`.

## Rules

- Do not add a lint suppression (`//nolint`, `#nosec`, `//lint:ignore`, `nosemgrep`, or an exclusion in `.golangci.yml`) without explicit maintainer approval. Correct the code so the linter passes.
- Handle every error. Never assign one to `_`.
- A meaningful string literal is a named constant.
- Pass `context.Context` as the first argument. Never store it in a struct field.
- Never commit a value from the maintainer's own accounts: an Auth0 tenant, domain, client ID or audience, an email address, a personal domain, a cloud account ID. Not as a fallback, default, example or test fixture. Read it from configuration and require it; examples use `example.com`. The module path `github.com/schmitthub/blackbox` and the `LICENSE` copyright line are the only exceptions.
- Pin every dependency, container image, GitHub Action and hook to an exact version with a digest or commit SHA.
- No `panic`. No `log.Fatal` or `os.Exit` outside `cmd/api/main.go`. Return the error up the call stack.
- Only `internal/config` reads the environment. Only `internal/server` starts an HTTP server.
- Every commit goes through the prek hooks. The `git-checks` guard blocks `--no-verify` and the other ways around them.
- Commits must be signed. `main` only takes squash merges from pull requests.
- Keep scanner versions in `prek.toml` and `.github/workflows/ci.yml` in step.
