# Copilot code review instructions

You review pull requests for this repository. `AGENTS.md` at the repository
root and the package `AGENTS.md` files are the coding standard. This file
tells you what to look for first and how to write each comment.

Read the head branch of the pull request. Compare every added or changed line
against the priorities below, in order.

## Priority 1: lint suppression

Flag every added or changed lint suppression. One comment per occurrence.

Markers to find in the diff:

- `//nolint` and `// nolint` (with or without a linter list)
- `#nosec`
- `//lint:ignore`
- `# nosemgrep`
- Changes to `exclusions`, `exclude`, or `nolintlint` settings in `.golangci.yml`

The repository rule (`AGENTS.md`, Rules) is: do not add a lint suppression
without explicit maintainer approval. Correct the code so the linter passes.
An explanation text after the marker is not sufficient on its own. In each
comment:

1. Quote the marker and the linter it silences.
2. State that the rule requires maintainer approval.
3. Propose the code change that removes the need for the suppression.

## Priority 2: routes, authorization, and user data

Applies to new or changed code in these paths:

- `internal/api/**`
- `internal/server/**`
- `cmd/api/**`
- `migrations/**`
- any file that builds or runs SQL

The rules are in `AGENTS.md`, Data rules. Report each of these as a blocking
finding:

- **No auth.** A route other than `/healthz` that is not behind the Auth0
  token validation. The API validates the Auth0 token and maps its subject to
  a row in `users`.
- **Hand-written auth.** A token parser, signature check, password check,
  session store, or API key comparison written in this repository. Identity
  comes from Auth0 only.
- **Unscoped data access.** A query on `inputs`, `outputs`, `events`,
  `event_inputs`, `event_outputs`, or `input_components` that does not
  restrict rows to the authenticated user's `user_id`, directly or through a
  join. A `user_id` taken from the request body, path, or query string
  instead of from the validated token.
- **SQL built from input.** A query assembled with string concatenation or
  `fmt.Sprintf` from request data. Queries use placeholders.
- **Rewritten history.** An `UPDATE` or `DELETE` on `events`. The table is
  append-only.
- **Local time.** A time written to the database that is not UTC, or a
  `timestamp` column without time zone.
- **Edited migration.** A change to a migration file that already exists on
  `main`. A schema change is a new goose migration with both `Up` and `Down`.
- **Crash path.** `panic` anywhere, or `log.Fatal` or `os.Exit` outside
  `cmd/api/main.go`. Return the error up the call stack.
- **Unbounded server.** An `http.Server` without `ReadHeaderTimeout`, or a
  server started outside `internal/server`, which owns graceful shutdown.

## Priority 3: `CLAUDE.md` files

Every `CLAUDE.md` in this repository is a symbolic link to the file
`AGENTS.md` in the same directory.

For each added or changed `CLAUDE.md` in the diff, check the file mode and
the blob content. A symbolic link has mode `120000`, and its blob content is
the link target string. Report each of these as a blocking finding:

- A regular file named `CLAUDE.md` (mode `100644` or `100755`).
- A link whose target is an absolute path.
- A link whose target is not exactly `AGENTS.md` (for example
  `../AGENTS.md`, `docs/AGENTS.md`, or `./AGENTS.md`).
- A link whose sibling `AGENTS.md` does not exist in that directory.

The fix is always the same: move the content to the sibling `AGENTS.md` and
replace `CLAUDE.md` with a relative link to it.

## Priority 4: standing rules from `AGENTS.md`

Flag these when they appear in the diff. Name the rule section in the comment.

- An error assigned to `_` or otherwise not handled.
- A GitHub Action without a full commit SHA, or a commit hook or scanner
  without an exact version.
- A scanner version in `.github/workflows/ci.yml` that differs from the same
  scanner's version in `prek.toml`.
- Logic in `cmd/api`. It only wires config, the database pool, the router,
  and the server.
- A read of the environment (`os.Getenv`, `os.LookupEnv`, `viper`) outside
  `internal/config`.
- A new attribute stored as its own column when it is not queried on
  regularly. New attributes start in `attrs` (jsonb).
- A stored statement that an input causes an output. Inputs and outputs
  relate only through events and time.

## Do not report

- Formatting that `gofmt`, `golines`, or import ordering already enforce.
- Word choice in code comments.
- A finding that a CI check on the same pull request already reports.

## Comment style

- Write in plain, direct English. One sentence, one idea.
- One finding per comment. Anchor the comment to the line.
- Name the rule file and section the finding comes from.
- Give the fix, not only the problem.

## Standards by path

Read the package `AGENTS.md` files along each changed file's path; they hold
the package requirements. Do not copy a path table here.
