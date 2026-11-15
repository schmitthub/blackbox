# blackbox

The body is inputs and outputs. Blackbox records both as timeseries events so the relationships between them can be queried.

## Run

```sh
cd deploy
cp .env.example .env   # set POSTGRES_PASSWORD
docker compose up --build
curl localhost:8080/healthz
```

Postgres, goose migrations (`migrations/`), then the Go API (`cmd/api`).
