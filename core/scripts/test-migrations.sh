#!/usr/bin/env bash
# A mock migration: runs the real migrations with the goose command line on
# an embedded PostgreSQL that lives for this run only, all the way up, all
# the way down, and up again. Any error goose reports fails the run.
# No container.
#
# Usage, from the repository root: core/scripts/test-migrations.sh
#
# Needs goose and embedded-postgres, both pinned in mise.toml (`mise install`).

set -euo pipefail

if [[ ! -d core/migrations ]]; then
	echo "run this from the repository root: core/scripts/test-migrations.sh" >&2
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
# script ends.
if [[ -z ${DATABASE_URL:-} ]]; then
	exec embedded-postgres exec -- "$0"
fi

export GOOSE_DRIVER=postgres GOOSE_DBSTRING=$DATABASE_URL GOOSE_MIGRATION_DIR=core/migrations

goose up
goose down-to 0
goose up
