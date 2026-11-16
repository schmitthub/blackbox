//go:build integration

package migrations_test

import (
	"context"
	"database/sql"
	"os"
	"slices"
	"testing"

	postgres "github.com/fergusstrange/embedded-postgres/v2"
	"github.com/fergusstrange/embedded-postgres/v2/eptest"
	_ "github.com/jackc/pgx/v5/stdlib" // registers the "pgx" database/sql driver
	"github.com/pressly/goose/v3"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	driverName    = "pgx"
	migrationsDir = "."

	// Everything a migration can leave in the public schema: tables,
	// indexes, sequences, views and composite types. goose's own version
	// table is not part of the schema under test.
	objectsQuery = `
		select c.relkind::text || ' ' || c.relname
		from pg_class c
		where c.relnamespace = 'public'::regnamespace
		  and c.relname not like 'goose_db_version%'
		order by 1`

	columnsQuery = `
		select table_name || '.' || column_name || ' ' || data_type
		       || ' null=' || is_nullable || ' default=' || coalesce(column_default, '')
		from information_schema.columns
		where table_schema = 'public' and table_name <> 'goose_db_version'
		order by table_name, ordinal_position`

	constraintsQuery = `
		select conrelid::regclass::text || ' ' || conname || ' ' || pg_get_constraintdef(oid)
		from pg_constraint
		where connamespace = 'public'::regnamespace
		  and conrelid::regclass::text <> 'goose_db_version'
		order by 1`

	indexesQuery = `
		select indexdef
		from pg_indexes
		where schemaname = 'public' and tablename <> 'goose_db_version'
		order by 1`

	// AGENTS.md, Data rules: all times are stored in UTC, in timestamptz columns.
	localTimeColumnsQuery = `
		select table_name || '.' || column_name
		from information_schema.columns
		where table_schema = 'public' and table_name <> 'goose_db_version'
		  and data_type = 'timestamp without time zone'
		order by 1`
)

func TestMigrations(t *testing.T) {
	ctx := t.Context()
	db := startPostgres(t)

	provider, err := goose.NewProvider(goose.DialectPostgres, db, os.DirFS(migrationsDir))
	require.NoError(t, err)

	sources := provider.ListSources()
	require.NotEmpty(t, sources, "no migrations found")

	// Every migration goes up, down and up again, so each Down runs
	// against exactly the schema its Up left.
	for _, source := range sources {
		_, err = provider.UpByOne(ctx)
		require.NoError(t, err, "up %s", source.Path)

		_, err = provider.Down(ctx)
		require.NoError(t, err, "down %s", source.Path)

		_, err = provider.UpByOne(ctx)
		require.NoError(t, err, "second up %s", source.Path)
	}

	version, err := provider.GetDBVersion(ctx)
	require.NoError(t, err)
	assert.Equal(t, sources[len(sources)-1].Version, version)

	want := schema(ctx, t, db)
	require.NotEmpty(t, want)

	assert.Empty(t, rows(ctx, t, db, localTimeColumnsQuery), "time columns that are not timestamptz")

	// All the way down leaves nothing behind.
	_, err = provider.DownTo(ctx, 0)
	require.NoError(t, err)
	assert.Empty(t, rows(ctx, t, db, objectsQuery), "objects left after every Down")

	// All the way up in one run gives the same schema as step by step.
	_, err = provider.Up(ctx)
	require.NoError(t, err)
	assert.Equal(t, want, schema(ctx, t, db))
}

// startPostgres runs a PostgreSQL server of its own for the test and
// returns a connection to it. eptest stops the server when the test ends.
func startPostgres(t *testing.T) *sql.DB {
	t.Helper()

	server := eptest.Start(t, postgres.DefaultConfig().Version(postgres.V18).Port(0))

	db, err := sql.Open(driverName, server.ConnectionURL())
	require.NoError(t, err)
	t.Cleanup(func() { assert.NoError(t, db.Close()) })

	return db
}

// schema describes every object, column, constraint and index in the
// public schema, as sorted lines that two runs can be compared by.
func schema(ctx context.Context, t *testing.T, db *sql.DB) []string {
	t.Helper()

	return slices.Concat(
		rows(ctx, t, db, objectsQuery),
		rows(ctx, t, db, columnsQuery),
		rows(ctx, t, db, constraintsQuery),
		rows(ctx, t, db, indexesQuery),
	)
}

// rows runs a query that returns one text column.
func rows(ctx context.Context, t *testing.T, db *sql.DB, query string) []string {
	t.Helper()

	result, err := db.QueryContext(ctx, query)
	require.NoError(t, err)

	defer func() { assert.NoError(t, result.Close()) }()

	var lines []string

	for result.Next() {
		var line string
		require.NoError(t, result.Scan(&line))

		lines = append(lines, line)
	}

	require.NoError(t, result.Err())

	return lines
}
