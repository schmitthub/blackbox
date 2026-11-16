#!/usr/bin/env bash
# A mock migration: runs the real migrations with the goose command line on
# an embedded PostgreSQL that lives for this run only, all the way up, all
# the way down, and up again. Any error goose reports fails the run.
# No container.
#
# Usage, from the repository root: core/scripts/test-migrations.sh
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

export GOOSE_DRIVER=postgres GOOSE_DBSTRING=$DATABASE_URL GOOSE_MIGRATION_DIR=migrations

goose up
goose down-to 0
goose up
