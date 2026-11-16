# mcp

The Go module of the Blackbox MCP server (`github.com/schmitthub/blackbox/mcp`). It is a scaffold: `server.Run` returns `ErrNotImplemented`. The repository-wide rules in `../AGENTS.md` apply here too.

## Layout

- `cmd/mcp/`: the binary. It only wires the logger and the server.
- `internal/server/`: the MCP server.
- `mise.toml`, `mise.lock`: the tools this module needs: Go, golangci-lint.
- `prek.toml`: this module's commit hooks. `.golangci.yml`: lint configuration.
- `ci.json`: what CI runs for this module: the make targets under `checks`, and the CodeQL languages.

## Commands

These targets are in `mcp/Makefile`. Run them in `mcp/`, or from the repository root with `make -C mcp <target>`.

- `make build`: the server binary, to `mcp/bin/mcp`.
- `make test`, `make lint`: unit tests and golangci-lint.

## Rules

- Handle every error. Never assign one to `_`.
- A meaningful string literal is a named constant.
- Pass `context.Context` as the first argument. Never store it in a struct field.
- No `panic`. No `log.Fatal` or `os.Exit` outside `cmd/mcp/main.go`. Return the error up the call stack.
