#!/usr/bin/env bash
# Sets up a checkout of Blackbox. Safe to run again: each part only does
# what is still missing.
#
# Usage: scripts/setup.sh [--env] [--auth0]
#
#   --env    deploy/.env: create it from deploy/.env.example, or add the
#            keys the example has and the file lacks. Never changes a value
#            that is already there.
#   --auth0  the Auth0 tenant: the API and the MCP client application, from
#            the AUTH0_* settings in deploy/.env. Needs `auth0 login`. Runs
#            --env first, because it reads that file.
#
# No flag runs every part.

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file=$root/deploy/.env
env_example=$root/deploy/.env.example

usage() {
	sed -n '2,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

run_env=false
run_auth0=false

if [[ $# -eq 0 ]]; then
	run_env=true
	run_auth0=true
fi

for arg in "$@"; do
	case $arg in
	--env) run_env=true ;;
	--auth0) run_auth0=true ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $arg" >&2
		usage >&2
		exit 2
		;;
	esac
done

# The Auth0 part reads deploy/.env.
if $run_auth0; then
	run_env=true
fi

setup_env() {
	if [[ ! -f $env_file ]]; then
		install -m 600 "$env_example" "$env_file"
		echo "env: created deploy/.env from deploy/.env.example"
		return
	fi

	local line key
	while IFS= read -r line; do
		[[ $line =~ ^([A-Z0-9_]+)= ]] || continue
		key=${BASH_REMATCH[1]}
		if ! grep -q "^$key=" "$env_file"; then
			printf '%s\n' "$line" >>"$env_file"
			echo "env: added $key to deploy/.env"
		fi
	done <"$env_example"
}

# set_env KEY VALUE: sets KEY in deploy/.env, in place.
set_env() {
	local key=$1 value=$2 tmp

	if grep -qxF "$key=$value" "$env_file"; then
		return
	fi

	tmp=$(mktemp "$env_file.XXXXXX")
	awk -v key="$key" -v value="$value" '
		index($0, key "=") == 1 { print key "=" value; done = 1; next }
		{ print }
		END { if (!done) print key "=" value }
	' "$env_file" >"$tmp"
	chmod 600 "$tmp"
	mv "$tmp" "$env_file"
	echo "env: set $key in deploy/.env"
}

setup_auth0() {
	local out key value

	out=$(
		set -a
		# shellcheck source=deploy/.env.example
		. "$env_file"
		set +a
		"$root/scripts/auth0-setup.sh"
	)

	while IFS='=' read -r key value; do
		set_env "$key" "$value"
	done <<<"$out"
}

if $run_env; then
	setup_env
fi

if $run_auth0; then
	setup_auth0
fi
