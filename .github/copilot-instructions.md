# Copilot code review instructions

You review pull requests for this repository. `AGENTS.md` at the repository
root and the package `AGENTS.md` files are the coding standard. This file
tells you what to look for first and how to write each comment.

Read the head branch of the pull request. Compare every added or changed line
against the priorities below, in order.

## Priority 1: authorization and user data

Applies to `internal/api/**` and to any file that builds or runs SQL. The
rules are in `AGENTS.md`, Data rules. Report each of these as a blocking
finding:

- **No auth.** A route other than `/healthz` that is not behind the Auth0
  token validation.
- **Hand-written auth.** A token, password, session, or API key check written
  in this repository. Identity comes from Auth0 only.
- **Unscoped data access.** A query on a user-owned table that does not
  restrict rows to the `user_id` of the validated token, or that takes
  `user_id` from the request.
- **SQL built from input.** A query assembled from request data instead of
  placeholders.

## Priority 2: schema and the event log

Applies to `migrations/**` and to any file that builds or runs SQL. The rules
are in `AGENTS.md`, Data rules. Report each of these as a blocking finding:

- **Edited migration.** A change to a migration file that is on `main`. A
  schema change is a new goose migration with `Up` and `Down`.
- **Rewritten history.** An `UPDATE` or `DELETE` on `events`.
- **Local time.** A stored time that is not UTC, or a time column that is not
  `timestamptz`.
- **Stored causation.** A table or column that records an input causing an
  output. They relate only through events and time.
- **Early column.** A new attribute stored as a column instead of in `attrs`
  when it is not queried on regularly.

## Priority 3: package boundaries

The rules are in `AGENTS.md`, Layout and Rules. Flag these:

- Logic in `cmd/api`. It only wires config, the database pool, the router,
  and the server.
- A read of the environment outside `internal/config`.
- An HTTP server started outside `internal/server`.
- `panic` anywhere, or `log.Fatal` or `os.Exit` outside `cmd/api/main.go`.

## Do not report

- Formatting and lint findings. golangci-lint runs on the pull request.
- The `AGENTS.md` and `CLAUDE.md` layout. The `Agent compatibility` check
  runs on the pull request.
- Any other finding that a CI check on the same pull request already reports.

## Comment style

- One finding per comment, anchored to the line.
- Name the `AGENTS.md` section the finding comes from.
- Give the fix, not only the problem.

## Standards by path

Read the package `AGENTS.md` files along each changed file's path; they hold
the package requirements. Do not copy a path table here.
