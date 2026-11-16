#!/usr/bin/env bash
# Tests the migrations by running them: the real goose command line on an
# embedded PostgreSQL that lives for this run only. No container.
#
# Usage, from the repository root: core/scripts/test-migrations.sh
#
# Checks:
#   - every migration goes up, down and up again, one at a time
#   - all the way down leaves nothing in the public schema
#   - one full `up` gives the same schema as step by step
#   - no time column is without a time zone (AGENTS.md, Migrations)
#
# Needs Go. It installs the two tools below, at these versions, into a
# temporary directory.

set -euo pipefail

# Keep goose in step with the image in deploy/compose.yaml.
goose_version=v3.30.1
embedded_postgres_version=v2.0.1
postgres_version=18.6.1

if [[ ! -d migrations ]]; then
	echo "run this from the repository root: core/scripts/test-migrations.sh" >&2
	exit 1
fi

# First pass: install the tools, then run this script again inside
# `embedded-postgres exec`, which starts PostgreSQL, sets DATABASE_URL and
# the PG* variables, and stops PostgreSQL when the script ends.
if [[ -z ${DATABASE_URL:-} ]]; then
	bin=$(mktemp -d)
	trap 'rm -rf "$bin"' EXIT

	GOBIN=$bin go install "github.com/pressly/goose/v3/cmd/goose@$goose_version"
	GOBIN=$bin go install "github.com/fergusstrange/embedded-postgres/v2/cmd/embedded-postgres@$embedded_postgres_version"

	PATH=$bin:$PATH embedded-postgres exec --postgres-version "$postgres_version" -- "$0"
	exit
fi

# psql and pg_dump come with the PostgreSQL that embedded-postgres downloaded.
cache=${XDG_CACHE_HOME:-$HOME/.cache}/embedded-postgres/v2
shopt -s nullglob
client_dirs=("$cache/postgresql-$postgres_version-"*/*/bin)
[[ ${#client_dirs[@]} -gt 0 ]] || {
	echo "no PostgreSQL $postgres_version client programs under $cache" >&2
	exit 1
}
PATH=${client_dirs[0]}:$PATH

export GOOSE_DRIVER=postgres GOOSE_DBSTRING=$DATABASE_URL GOOSE_MIGRATION_DIR=migrations

# sql QUERY: prints the rows, one per line.
sql() {
	psql -v ON_ERROR_STOP=1 -At -c "$1" </dev/null
}

dump_schema() {
	pg_dump --schema-only --no-owner --exclude-table='goose_db_version*' --restrict-key=test </dev/null
}

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

migrations=(migrations/*.sql)
[[ ${#migrations[@]} -gt 0 ]] || fail "no migrations found"

for migration in "${migrations[@]}"; do
	echo "== $migration: up, down, up"
	goose up-by-one
	goose down
	goose up-by-one
done

stepwise=$(dump_schema)

local_time=$(sql "
	select table_name || '.' || column_name
	from information_schema.columns
	where table_schema = 'public' and table_name <> 'goose_db_version'
	  and data_type = 'timestamp without time zone'")
[[ -z $local_time ]] || fail "time columns without a time zone: $local_time"

echo "== down to 0"
goose down-to 0

left=$(sql "
	select c.relname
	from pg_class c
	where c.relnamespace = 'public'::regnamespace
	  and c.relname not like 'goose_db_version%'")
[[ -z $left ]] || fail "objects left after every Down: $left"

echo "== up"
goose up

full=$(dump_schema)
if [[ $stepwise != "$full" ]]; then
	diff <(echo "$stepwise") <(echo "$full") >&2 || true
	fail "one full up gives a different schema than step by step"
fi

echo "PASS: ${#migrations[@]} migration(s)"
