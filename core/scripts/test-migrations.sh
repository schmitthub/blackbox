#!/usr/bin/env bash
# A mock migration: runs the real migrations with the goose command line on
# an embedded PostgreSQL that lives for this run only, all the way up, all
# the way down, and up again. Any error goose reports fails the run.
# No container.
#
# Usage: make test-migrations, or from core/: scripts/test-migrations.sh
#
# Needs goose and embedded-postgres, both pinned in core/mise.toml (`mise install`).

set -euo pipefail

if [[ ! -d migrations || ! -f go.mod ]]; then
	echo "run this from core/: scripts/test-migrations.sh" >&2
	exit 1
fi

for tool in goose embedded-postgres; do
	command -v "$tool" >/dev/null || {
		echo "$tool not found: run \`mise install\`" >&2
		exit 1
	}
done

# First pass: run this script again inside `embedded-postgres exec`, which
# starts PostgreSQL, sets DATABASE_URL, and stops PostgreSQL when the
# script ends. Only --inside marks the second pass: a DATABASE_URL already
# in the environment may point at a real database and is never used.
if [[ ${1:-} != --inside ]]; then
	exec embedded-postgres exec -- "$0" --inside
fi

export GOOSE_DRIVER=postgres GOOSE_DBSTRING=$DATABASE_URL GOOSE_MIGRATION_DIR=migrations

goose up
goose down-to 0
goose up
