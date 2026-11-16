# blackbox

The body is inputs and outputs. Blackbox records both as timeseries events so the relationships between them can be queried.

## Run

```sh
scripts/setup.sh --env   # creates .env; set POSTGRES_PASSWORD in it
make up
curl localhost:8080/healthz
```

`make help` lists the repository-wide targets. Each project has its own: `make -C core help`, `make -C mcp help`.

## Setup

`scripts/setup.sh` sets up a checkout and is safe to run again. With no flag it runs every part.

- `--env`: creates `.env` from `.env.example`, or adds the keys the file lacks. It never changes a value that is already there.
- `--auth0`: creates or updates the Auth0 API and the MCP client application from the `AUTH0_*` settings in `.env`. Run `auth0 login` first. It runs `--env` first, and writes the tenant domain and the client ID back to `.env`.

Tools come from `mise install --monorepo`.

Postgres, goose migrations (`core/migrations/`), then the Go API (`core/cmd/api`).
