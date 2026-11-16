# core

The Go module of the Blackbox monolith (`github.com/schmitthub/blackbox/core`): the API and everything it is built from. The repository-wide rules in `../AGENTS.md` apply here too.

## Layout

- `cmd/api/`: the binary. It only wires config, the database pool, the router and the server.
- `internal/config/`: configuration from the environment.
- `internal/api/`: HTTP routes and handlers.
- `internal/server/`: HTTP server lifecycle.
- `migrations/`: goose migrations.
- `scripts/`: test helpers, run from `core/` (the make targets do that).
- `mise.toml`, `mise.lock`: the tools this module needs: Go, golangci-lint, mockery, goose, embedded-postgres.
- `ci.json`: what CI runs for this module: the make targets under `checks`, and the CodeQL languages.
- `prek.toml`: this module's commit hooks. `.golangci.yml`, `.mockery.yml`: lint and mock configuration.

## Commands

These targets are in `core/Makefile`. Run them in `core/`, or from the repository root with `make -C core <target>`.

- `make build`: the API binary, to `core/bin/api`.
- `make test`, `make lint`: unit tests and golangci-lint.
- `make test-int`: integration tests. Each starts an embedded PostgreSQL of its own; no container is needed.
- `make test-migrations`: runs the real migrations up, down and up on an embedded PostgreSQL. No container is needed.
- `make check-mocks`: regenerates the mocks and fails when a committed one changes.
- `make mocks`: regenerate the mocks listed in `.mockery.yml`. Add an interface there; never edit or hand-write a mock.

## Data rules

- Identity comes from Auth0. The API validates the Auth0 token and maps its subject to a row in `users`. Write no token, password, session or API key check here. Only `/healthz` is public.
- Every row in `inputs`, `outputs` and `events` belongs to one user. Every query restricts rows to the `user_id` of the validated token, never to one taken from the request.
- Queries use placeholders. Never build SQL from request data.
- `events` is append-only. No `UPDATE` or `DELETE` on it.
- Inputs and outputs relate only through events and time. Nothing stores that an input causes an output.

## Migrations

- A schema change is a new goose migration with `Up` and `Down`. Never edit a migration that is on `main`.
- All times are stored in UTC, in `timestamptz` columns.
- A new attribute starts in `attrs` (jsonb). It earns a column, through a migration, when it is queried on regularly.
- Migrations are tested by running them, never from Go code: `make test-migrations` (`scripts/test-migrations.sh`) is a mock migration: it runs the real goose command line on an embedded PostgreSQL, without containers, all the way up, down and up again, and fails on any error.

## Rules

- Handle every error. Never assign one to `_`.
- A meaningful string literal is a named constant.
- Pass `context.Context` as the first argument. Never store it in a struct field.
- No `panic`. No `log.Fatal` or `os.Exit` outside `cmd/api/main.go`. Return the error up the call stack.
- Only `internal/config` reads the environment. Only `internal/server` starts an HTTP server.

## Tests

- A unit test replaces a dependency only with a mockery mock (`make mocks`). Never hand-write a fake, stub or spy.
- A test that needs a database is an integration test: it carries `//go:build integration`, starts an embedded PostgreSQL, and runs with `make test-int`. `make test` needs no service and no network.
- End-to-end tests run against the Compose stack in containers. Integration tests and the migration test never use containers.
