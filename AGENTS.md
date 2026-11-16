# Blackbox

Blackbox records what goes into the body and what comes out of it as timeseries events, so the relationships between them can be queried. It is a monolithic monorepo: the Go API (Gin) on PostgreSQL lives in `core/` and runs with Docker Compose; the MCP server lives in `mcp/`.

## Shared instructions

Claude Code and Codex use the same project instructions and skills.

- Store instructions in regular `AGENTS.md` files. Each must have a sibling `CLAUDE.md` symbolic link with the relative target `AGENTS.md`.
- A requirement for one package tree lives in that tree's `AGENTS.md`. Read the `AGENTS.md` files along the path to each file you change.
- Shared skills live in `.agents/skills/`, one `SKILL.md` per skill directory. `.claude/skills` links to it; Codex discovers it directly.
- Keep `.agents/` independent of any harness. Native settings and tool-specific hooks stay in `.claude/` or `.codex/`. Never link from `.agents/` into either.
- Shared command guards live in `.agents/hooks/`. Both `.claude/settings.json` and `.codex/config.toml` register them. The Codex hooks use inline TOML; do not add `.codex/hooks.json`, or each guard registers twice.
- Symbolic links under `.agents/`, `.claude/` and `.codex/` are relative and stay inside the repository.

Copilot code review reads `.github/copilot-instructions.md` and the procedure in `.github/skills/code-review/SKILL.md`. Both point at the rules in this file; add a rule here, not there.

The `agent-compat` commit hook and the CI job `Agent compatibility` run `scripts/check-agent-compatibility.py`, which enforces the layout above. CI also runs its tests, `scripts/test_agent_compatibility.py`.

## Layout

- `core/`: the Go module of the monolith: the API, its migrations and everything it is built from. Its instructions are in `core/AGENTS.md`.
- `mcp/`: the Go module of the MCP server, a scaffold for now. Its instructions are in `mcp/AGENTS.md`.
- `deploy/`: Compose files and one subdirectory per service.
- `scripts/`: repository setup and checks, and `ci-plan.sh`, which decides what CI runs.

## Commands

Run every command and every script in `scripts/` from the repository root; they use paths relative to it.

- `make help` lists the repository-wide targets (Compose, hooks). The root `Makefile` holds nothing that belongs to a project; each project's targets are in its own `Makefile` (`core/Makefile`, `mcp/Makefile`).
- `scripts/setup.sh [--env] [--auth0]`: sets up a checkout; no flag runs every part. A new part is a flag there, is safe to run again, and takes its settings from `.env`. A new setting gets a line in `.env.example`.
- `make check`: every commit hook on all files.
- `make up`, `make down`, `make reset`: the Compose stack. `make reset` deletes the database volume.

## Rules

- Do not add a lint suppression (`//nolint`, `#nosec`, `//lint:ignore`, `nosemgrep`, or an exclusion in a project's `.golangci.yml`) without explicit maintainer approval. Correct the code so the linter passes.
- Never commit a value from the maintainer's own accounts: an Auth0 tenant, domain, client ID or audience, an email address, a personal domain, a cloud account ID. Not as a fallback, default, example or test fixture. Read it from configuration and require it; examples use `example.com`. The module path `github.com/schmitthub/blackbox` and the `LICENSE` copyright line are the only exceptions.
- Pin every dependency, container image, GitHub Action and hook to an exact version with a digest or commit SHA.
- Command-line tools are pinned with mise, each next to what uses it: repository-wide tools in the root `mise.toml`, a project's tools in its own (`core/mise.toml`, `mcp/mise.toml`). The root file lists the projects in `[monorepo] config_roots`. Each `mise.toml` has a `mise.lock` with checksums beside it; after changing one, run `mise lock` in that directory and commit both. `mise install --monorepo` installs everything. CI installs them with `jdx/mise-action`; never write a tool version into a workflow or a script.
- Commit hooks follow the same split: repository-wide hooks in the root `prek.toml`, a project's hooks in its own (`core/prek.toml`, `mcp/prek.toml`). prek finds both from the root.
- Every commit goes through the prek hooks. The `git-checks` guard blocks `--no-verify` and the other ways around them.
- Commits must be signed. `main` only takes squash merges from pull requests.
- CI holds no project. `.github/workflows/ci.yml` is the one workflow; its `plan` job (`scripts/ci-plan.sh`) finds the projects and decides what runs, and the jobs after it run once per project through a matrix. Never add a job for one project to a workflow.
- A project is a top-level directory with a `ci.json`: its `name`, its `checks` (make targets of its `Makefile`; CI runs `make -C <dir> <check>` with the tools of its `mise.toml`) and its `codeql` languages. To add a check, add a make target and name it in `ci.json`. To add a project, add its directory with `Makefile`, `mise.toml`, `prek.toml`, `AGENTS.md` and `ci.json`, and list it in `[monorepo] config_roots` and `.github/dependabot.yml`.
- CodeQL scans each project on its own, with the category `/language:<language>;project:<dir>`. Never use a workflow-level `paths` filter: it leaves required checks pending.
- The `main` ruleset requires one status check per project (`Core Status`, `MCP Status`) and `Repository Status` for the repository-wide jobs. CI creates a project's status from its `ci.json`; adding it to the ruleset is the maintainer's step.
- Keep scanner versions in the `prek.toml` files and the workflows in step.
