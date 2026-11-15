#!/usr/bin/env bash
# Sets up an Auth0 tenant for Blackbox: the API (resource server) and the
# MCP client application. Safe to run again: it finds each resource first
# and only creates what is missing.
#
# Needs the auth0 CLI and jq (`mise install`), and a CLI session on the
# tenant to set up:
#
#   auth0 login
#   auth0 login --domain <tenant> --client-id <id> --client-secret <secret>
#
# Usage:
#
#   BLACKBOX_AUDIENCE=https://blackbox.example.com/api \
#   BLACKBOX_MCP_CALLBACKS=https://mcp.example.com/callback \
#     scripts/auth0-setup.sh
#
# Settings, all from the environment:
#
#   BLACKBOX_AUDIENCE       required. Identifier of the API; the `aud` of its
#                           tokens. Any URI you own. It cannot change later.
#   BLACKBOX_MCP_CALLBACKS  required. Comma-separated redirect URLs of the
#                           MCP client.
#   BLACKBOX_API_NAME       name of the API. Default: Blackbox API
#   BLACKBOX_MCP_NAME       name of the MCP application. Default: Blackbox MCP
#   BLACKBOX_TOKEN_LIFETIME access token lifetime, seconds. Default: 86400

set -euo pipefail

audience=${BLACKBOX_AUDIENCE:?set BLACKBOX_AUDIENCE to the API identifier, e.g. https://blackbox.example.com/api}
callbacks=${BLACKBOX_MCP_CALLBACKS:?set BLACKBOX_MCP_CALLBACKS to the redirect URLs of the MCP client}
api_name=${BLACKBOX_API_NAME:-Blackbox API}
mcp_name=${BLACKBOX_MCP_NAME:-Blackbox MCP}
token_lifetime=${BLACKBOX_TOKEN_LIFETIME:-86400}

for tool in auth0 jq; do
	command -v "$tool" >/dev/null || {
		echo "$tool not found: run \`mise install\`" >&2
		exit 1
	}
done

domain=$(auth0 tenants list --json 2>/dev/null | jq -r '.[] | select(.active) | .name') || true
if [[ -z $domain ]]; then
	echo "no active Auth0 tenant: run \`auth0 login\` first" >&2
	exit 1
fi

echo "Tenant: $domain" >&2

# The API. Its identifier is the lookup key; Auth0 never lets it change.
api_id=$(auth0 apis list --number 1000 --json |
	jq -r --arg id "$audience" '.[] | select(.identifier == $id) | .id')

if [[ -z $api_id ]]; then
	auth0 apis create \
		--name "$api_name" \
		--identifier "$audience" \
		--signing-alg RS256 \
		--token-lifetime "$token_lifetime" \
		--offline-access=true \
		--json >/dev/null
	echo "API: created $audience" >&2
else
	auth0 apis update "$api_id" \
		--name "$api_name" \
		--signing-alg RS256 \
		--token-lifetime "$token_lifetime" \
		--offline-access=true \
		--json >/dev/null
	echo "API: updated $audience" >&2
fi

# The MCP client: a public application (no client secret) that signs users
# in with the authorization code flow and PKCE.
app_flags=(
	--name "$mcp_name"
	--description "Blackbox MCP server"
	--type native
	--auth-method None
	--grants "code,refresh-token"
	--callbacks "$callbacks"
	--json
)

mcp_client_id=$(auth0 apps list --number 1000 --json |
	jq -r --arg name "$mcp_name" '.[] | select(.name == $name) | .client_id')

if [[ -z $mcp_client_id ]]; then
	mcp_client_id=$(auth0 apps create "${app_flags[@]}" | jq -r '.client_id')
	echo "MCP application: created $mcp_name" >&2
else
	auth0 apps update "$mcp_client_id" "${app_flags[@]}" >/dev/null
	echo "MCP application: updated $mcp_name" >&2
fi

# Nothing below is secret.
cat <<EOF
AUTH0_DOMAIN=$domain
AUTH0_AUDIENCE=$audience
AUTH0_MCP_CLIENT_ID=$mcp_client_id
EOF
