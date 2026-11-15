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
- `nosemgrep`
- Changes to `exclusions`, `exclude`, or `nolintlint` settings in `.golangci.yml`

The repository rule (`AGENTS.md`, Rules) is: do not add a lint suppression
without explicit maintainer approval. Correct the code so the linter passes.
An explanation text after the marker is not sufficient on its own. In each
comment:

1. Quote the marker and the linter it silences.
2. State that the rule requires maintainer approval.
3. Propose the code change that removes the need for the suppression.

## Priority 2: authorization, user data, and schema

Applies to `internal/api/**`, `migrations/**`, and any file that builds or
runs SQL. The rules are in `AGENTS.md`, Data rules. Report each of these as a
blocking finding:

- **No auth.** A route other than `/healthz` that is not behind the Auth0
  token validation.
- **Hand-written auth.** A token, password, session, or API key check written
  in this repository. Identity comes from Auth0 only.
- **Unscoped data access.** A query on a user-owned table that does not
  restrict rows to the `user_id` of the validated token, or that takes
  `user_id` from the request.
- **SQL built from input.** A query assembled from request data instead of
  placeholders.
- **Rewritten history.** An `UPDATE` or `DELETE` on `events`.
- **Local time.** A stored time that is not UTC, or a time column that is not
  `timestamptz`.
- **Edited migration.** A change to a migration file that is on `main`. A
  schema change is a new goose migration with `Up` and `Down`.
- **Crash path.** `panic` anywhere, or `log.Fatal` or `os.Exit` outside
  `cmd/api/main.go`.

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
- A meaningful string literal that is not a named constant.
- A `context.Context` stored in a struct field.
- A dependency, container image, GitHub Action, or hook without an exact
  version and digest or commit SHA.
- Logic in `cmd/api`. It only wires config, the database pool, the router,
  and the server.
- A read of the environment outside `internal/config`, or an HTTP server
  started outside `internal/server`.

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
