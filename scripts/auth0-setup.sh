#!/usr/bin/env bash
# Sets up an Auth0 tenant for Blackbox: the API (resource server) and the
# MCP client application. Safe to run again: it finds each resource first,
# then creates or updates it.
#
# `scripts/setup.sh --auth0` runs this with the settings in deploy/.env.
# Run it directly only to try other settings.
#
# Needs the auth0 CLI and jq (`mise install`), and a CLI session on the
# tenant: `auth0 login`.
#
# Settings, all from the environment. Each has a default:
#
#   AUTH0_DOMAIN          tenant domain. Default: the CLI's active tenant.
#   AUTH0_AUDIENCE        identifier of the API; the `aud` of its tokens.
#                         It cannot change later. Default: urn:blackbox:api
#   AUTH0_API_NAME        name of the API. Default: Blackbox API
#   AUTH0_MCP_NAME        name of the MCP application. Default: Blackbox MCP
#   AUTH0_MCP_CALLBACKS   comma-separated redirect URLs of the MCP client.
#                         Default: http://localhost:8081/callback
#   AUTH0_TOKEN_LIFETIME  access token lifetime, seconds. Default: 86400
#
# Prints the resulting AUTH0_DOMAIN, AUTH0_AUDIENCE and AUTH0_MCP_CLIENT_ID
# as KEY=VALUE lines. None of them is secret.

set -euo pipefail

domain=${AUTH0_DOMAIN:-}
audience=${AUTH0_AUDIENCE:-urn:blackbox:api}
api_name=${AUTH0_API_NAME:-Blackbox API}
mcp_name=${AUTH0_MCP_NAME:-Blackbox MCP}
callbacks=${AUTH0_MCP_CALLBACKS:-http://localhost:8081/callback}
token_lifetime=${AUTH0_TOKEN_LIFETIME:-86400}

for tool in auth0 jq; do
	command -v "$tool" >/dev/null || {
		echo "$tool not found: run \`mise install\`" >&2
		exit 1
	}
done

tenants=$(auth0 tenants list --json 2>/dev/null) || tenants='[]'

if [[ -z $domain ]]; then
	domain=$(jq -r '.[] | select(.active) | .name' <<<"$tenants")
	if [[ -z $domain ]]; then
		echo "no Auth0 tenant: set AUTH0_DOMAIN in deploy/.env or run \`auth0 login\`" >&2
		exit 1
	fi
elif ! jq -e --arg d "$domain" 'any(.[]; .name == $d)' <<<"$tenants" >/dev/null; then
	echo "auth0 CLI is not logged in to $domain: run \`auth0 login --domain $domain\`" >&2
	exit 1
fi

echo "Tenant: $domain" >&2

# The API. Its identifier is the lookup key; Auth0 never lets it change.
api_id=$(auth0 apis list --tenant "$domain" --number 1000 --json |
	jq -r --arg id "$audience" '.[] | select(.identifier == $id) | .id')

api_flags=(
	--tenant "$domain"
	--name "$api_name"
	--signing-alg RS256
	--token-lifetime "$token_lifetime"
	--offline-access=true
	--json
)

if [[ -z $api_id ]]; then
	auth0 apis create --identifier "$audience" "${api_flags[@]}" >/dev/null
	echo "API: created $audience" >&2
else
	auth0 apis update "$api_id" "${api_flags[@]}" >/dev/null
	echo "API: updated $audience" >&2
fi

# The MCP client: a public application (no client secret) that signs users
# in with the authorization code flow and PKCE.
app_flags=(
	--tenant "$domain"
	--name "$mcp_name"
	--description "Blackbox MCP server"
	--type native
	--auth-method None
	--grants "code,refresh-token"
	--callbacks "$callbacks"
	--json
)

mcp_client_id=$(auth0 apps list --tenant "$domain" --number 1000 --json |
	jq -r --arg name "$mcp_name" '.[] | select(.name == $name) | .client_id')

if [[ -z $mcp_client_id ]]; then
	mcp_client_id=$(auth0 apps create "${app_flags[@]}" | jq -r '.client_id')
	echo "MCP application: created $mcp_name" >&2
else
	auth0 apps update "$mcp_client_id" "${app_flags[@]}" >/dev/null
	echo "MCP application: updated $mcp_name" >&2
fi

cat <<OUT
AUTH0_DOMAIN=$domain
AUTH0_AUDIENCE=$audience
AUTH0_MCP_CLIENT_ID=$mcp_client_id
OUT
