---
name: code-review
description: Review a pull request in this repository. Use this when asked to review a pull request, a diff, or a branch.
---

Follow these steps in order. `.github/copilot-instructions.md` defines each
priority in full and the comment style; this file is the procedure.

## 1. Lint suppression

Search every added or changed line in the diff for `//nolint`, `// nolint`,
`#nosec`, `//lint:ignore`, and `nosemgrep`. Search a project's `.golangci.yml` changes
for `exclusions`, `exclude`, and `nolintlint`. List every hit as `file:line`.
Report each hit as its own comment (priority 1).

## 2. Authorization, user data, and schema

Search the diff under `core/internal/api/` and `core/migrations/`, and every file that
builds or runs SQL. For each hit:

1. For each new route, confirm it is behind the Auth0 token validation, or
   that it is `/healthz`. Confirm no token, password, session, or key check
   is written in this repository.
2. For each query on a user-owned table, confirm it restricts rows to the
   `user_id` of the validated token, and that the `user_id` does not come
   from the request.
3. Confirm each query uses placeholders.
4. Confirm there is no `UPDATE` or `DELETE` on `events`, and that every
   stored time is UTC in a `timestamptz` column.
5. For each file under `core/migrations/`, confirm it is new, not an edit of a
   file on `main`, and that it has both `Up` and `Down`.
6. Confirm there is no `panic`, and no `log.Fatal` or `os.Exit` outside
   `core/cmd/api/main.go`.

Report each failed check as a blocking comment (priority 2).

## 3. `CLAUDE.md` files

For each `CLAUDE.md` in the diff, read the file mode and the blob content.
Pass only when the mode is `120000` and the content is exactly `AGENTS.md`,
and a file named `AGENTS.md` exists in the same directory. Report each
failure as a blocking comment (priority 3).

## 4. Version pins

For each added `FROM` line, `image:` line, `uses:` line, or `rev:` line,
confirm it carries a `@sha256:` digest or a full commit SHA. Report each miss
(priority 4).

## 5. Standing rules

Apply the remaining priority 4 rules.

## 6. Report

Write each comment as `.github/copilot-instructions.md` describes: one
finding per comment, the rule source named, the fix given.
