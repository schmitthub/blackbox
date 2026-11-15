# blackbox

The body is inputs and outputs. Blackbox records both as timeseries events so the relationships between them can be queried.

## Run

```sh
cp deploy/.env.example deploy/.env   # set POSTGRES_PASSWORD
make up
curl localhost:8080/healthz
```

`make help` lists every target: build, test, lint, compose operations.

Postgres, goose migrations (`migrations/`), then the Go API (`cmd/api`).
