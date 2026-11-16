#!/usr/bin/env bash
# Decides what CI runs. The `plan` job of .github/workflows/ci.yml runs this
# and turns each printed line into a job matrix.
#
# A project is a top-level directory with a ci.json:
#
#   name     shown in check names: "<name> / <check>", "<name> Status"
#   checks   make targets of the project; CI runs `make -C <dir> <check>`
#   codeql   CodeQL languages to scan the project with
#
# Environment:
#
#   EVENT       pull_request or push
#   HEAD_SHA    head commit of the pull request
#   BASE_SHA    head commit of the pull request's base branch
#   BASE_REF    the pull request's base branch
#   STACK       `github.event.pull_request.stack` as JSON; null outside a stack
#
# Prints four lines, NAME=JSON array:
#
#   projects    every project
#   checks      project and check pairs to run
#   scans       project and language pairs to scan with CodeQL
#   unchanged   project and language pairs that are not scanned
#
# On a pull request:
#
# - Checks run for a project that changed since the base of the stack, and
#   only on the two layers of a stack that GitHub's guide names: the top
#   layer, which holds the full set of changes, and the lowest unmerged
#   layer, which lands next. Outside a stack that is every pull request.
#   https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/optimizing-ci-for-stacked-pull-requests
# - A scan runs for a project that the layer's own diff changes, on every
#   layer: code scanning blocks a pull request only for alerts on lines of
#   its own diff, so each layer is scanned where its lines are.
# - A project counts as changed when a workflow or this script changes.
#
# On a push every project is scanned and no check runs: the code already
# passed, and pull request scans compare against the results on the branch.

set -euo pipefail

projects=$(
	for f in */ci.json; do
		jq -c --arg dir "${f%/ci.json}" '{dir: $dir} + .' "$f"
	done | jq -sc .
)

# Projects that a list of changed files (stdin) touches, as a JSON array of
# directories.
touched() {
	jq -Rsc --argjson projects "$projects" '
		split("\n") as $files
		| ($files | any(startswith(".github/workflows/") or . == "scripts/ci-plan.sh")) as $all
		| [$projects[].dir | select(. as $d | $all or ($files | any(startswith($d + "/"))))]'
}

if [[ $EVENT == pull_request ]]; then
	heavy=$(jq -n --argjson s "$STACK" --arg base "$BASE_REF" \
		'$s == null or $s.position == $s.size or $s.base.ref == $base')
	stack_base=$(jq -rn --argjson s "$STACK" --arg base "$BASE_REF" '$s.base.ref // $base')
	in_stack=$(git diff --name-only "origin/$stack_base...$HEAD_SHA" | touched)
	in_layer=$(git diff --name-only "$BASE_SHA...$HEAD_SHA" | touched)
else
	heavy=false
	in_stack='[]'
	in_layer=$(jq -c 'map(.dir)' <<<"$projects")
fi

jq -rn --argjson projects "$projects" --argjson heavy "$heavy" \
	--argjson in_stack "$in_stack" --argjson in_layer "$in_layer" '
	def pairs(key; name): [.[] | {dir, name} + (key[] | {(name): .})];
	($projects | map(select(.dir as $d | $in_layer | index($d)))) as $scanned
	| "projects=\($projects | map({dir, name}) | tojson)",
	  "checks=\($projects | map(select($heavy and (.dir as $d | $in_stack | index($d)))) | pairs(.checks; "check") | tojson)",
	  "scans=\($scanned | pairs(.codeql; "language") | tojson)",
	  "unchanged=\($projects - $scanned | pairs(.codeql; "language") | tojson)"'
