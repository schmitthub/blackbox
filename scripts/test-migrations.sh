#!/usr/bin/env bash
# Tests the migrations by running them: the same goose image and Compose
# service that production uses, on a throwaway database.
#
# Usage, from the repository root: scripts/test-migrations.sh
#
# Checks:
#   - every migration goes up, down and up again, one at a time
#   - all the way down leaves nothing in the public schema
#   - one full `up` gives the same schema as step by step
#   - no time column is without a time zone (AGENTS.md, Data rules)

set -euo pipefail

if [[ ! -f deploy/compose.yaml ]]; then
	echo "run this from the repository root: scripts/test-migrations.sh" >&2
	exit 1
fi

# A Compose project of its own, without compose.override.yaml: no published
# port, and a database volume apart from the one `make up` uses.
compose=(docker compose --env-file .env -p blackbox-migrations-test -f deploy/compose.yaml)

cleanup() {
	"${compose[@]}" down --volumes --remove-orphans >/dev/null 2>&1
}
trap cleanup EXIT
cleanup

goose() {
	"${compose[@]}" run --rm --quiet-pull migrate "$@" </dev/null
}

# sql QUERY: prints the rows, one per line.
sql() {
	"${compose[@]}" exec -T postgres psql -U blackbox -d blackbox -v ON_ERROR_STOP=1 -At -c "$1" </dev/null
}

dump_schema() {
	"${compose[@]}" exec -T postgres pg_dump -U blackbox -d blackbox --schema-only \
		--no-owner --exclude-table='goose_db_version*' --restrict-key=test </dev/null
}

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

shopt -s nullglob
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
