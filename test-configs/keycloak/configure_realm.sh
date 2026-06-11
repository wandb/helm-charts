#!/usr/bin/env bash
set -euo pipefail

# configure_realm.sh
# Purpose: Call Keycloak Admin API to:
#  - create or update a user (set username, password, and email)
#  - create a client by client-id if it doesn't exist
#
# Options (with defaults):
#  -u USERNAME   Username for the Keycloak user (default: wandb_user)
#  -p PASSWORD   Password for the user (default: wandb_user)
#  -e EMAIL      Email to assign to the user (default: user@example.com)
#  -c CLIENT_ID  Client ID to create if it doesn't exist (default: wandb)
#
# Optional environment variables / flags:
#  -r REALM            Realm to operate in (default: ${KC_REALM:-master})
#  -b BASE_URL         Base URL for Keycloak (default: ${KC_BASE_URL:-http://localhost:8080/keycloak})
#  --admin-user USER   Admin username for obtaining token (default: ${KC_ADMIN_USER:-admin})
#  --admin-pass PASS   Admin password for obtaining token (default: ${KC_ADMIN_PASS:-admin})
#  Environment overrides for the above defaults:
#    KC_USERNAME, KC_PASSWORD, KC_EMAIL, KC_CLIENT_ID
#
# Examples:
#  ./configure_realm.sh                      # uses all defaults
#  ./configure_realm.sh -u demo -p S3cret! -e demo@example.com -c demo-client
#  KC_BASE_URL=http://keycloak.my-domain/auth KC_REALM=myrealm ./configure_realm.sh -u u -p p -e e@x.com -c my-client
#
# Requirements: curl, jq

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -u USERNAME         Username to create/update (default: wandb_user)
  -p PASSWORD         Password for the user (will reset existing password) (default: wandb_user)
  -e EMAIL            Email for the user (default: user@example.com)
  -c CLIENT_ID        Client ID to create if it doesn't exist (default: wandb)
  -r REALM            Realm to operate in (default: master)
  -b BASE_URL         Keycloak base URL, e.g. http://localhost:8080/keycloak (default shown)
  --admin-user USER   Admin username (default: admin)
  --admin-pass PASS   Admin password (default: admin)
  -h                  Show this help

Environment overrides:
  KC_BASE_URL   Default base URL (same as -b)
  KC_REALM      Default realm (same as -r)
  KC_ADMIN_USER Default admin user
  KC_ADMIN_PASS Default admin password
  KC_USERNAME   Default username (same as -u)
  KC_PASSWORD   Default password (same as -p)
  KC_EMAIL      Default email (same as -e)
  KC_CLIENT_ID  Default client id (same as -c)
EOF
}

# Defaults (can be overridden by env or flags)
BASE_URL=${KC_BASE_URL:-http://localhost:8080/keycloak}
REALM=${KC_REALM:-master}
ADMIN_USER=${KC_ADMIN_USER:-admin}
ADMIN_PASS=${KC_ADMIN_PASS:-admin}

USERNAME=${KC_USERNAME:-wandb_user}
PASSWORD=${KC_PASSWORD:-wandb_user}
EMAIL=${KC_EMAIL:-user@example.com}
CLIENT_ID=${KC_CLIENT_ID:-wandb}

# Parse args
long_opts=(admin-user:,admin-pass:)
TEMP=$(getopt -o u:p:e:c:r:b:h --long "${long_opts[@]}" -n "$0" -- "$@") || { usage; exit 2; }
eval set -- "$TEMP"
while true; do
  case "$1" in
    -u) USERNAME="$2"; shift 2;;
    -p) PASSWORD="$2"; shift 2;;
    -e) EMAIL="$2"; shift 2;;
    -c) CLIENT_ID="$2"; shift 2;;
    -r) REALM="$2"; shift 2;;
    -b) BASE_URL="$2"; shift 2;;
    --admin-user) ADMIN_USER="$2"; shift 2;;
    --admin-pass) ADMIN_PASS="$2"; shift 2;;
    -h) usage; exit 0;;
    --) shift; break;;
    *) echo "Internal error parsing args" >&2; exit 2;;
  esac
done

# Validate required
if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$EMAIL" || -z "$CLIENT_ID" ]]; then
  echo "Error: -u, -p, -e, -c are required" >&2
  echo
  usage
  exit 2
fi

# Pre-flight
command -v curl >/dev/null 2>&1 || { echo "curl not found in PATH" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found in PATH" >&2; exit 1; }

API="$BASE_URL/admin/realms/$REALM"
TOKEN_URL="$BASE_URL/realms/$REALM/protocol/openid-connect/token"

log() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"; }

get_admin_token() {
  local token
  # Using admin-cli client
  set +e
  token=$(curl -sS -f \
    -X POST "$TOKEN_URL" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "client_id=admin-cli" \
    --data-urlencode "username=$ADMIN_USER" \
    --data-urlencode "password=$ADMIN_PASS" \
    -d "grant_type=password" | jq -r '.access_token' 2>/dev/null)
  local rc=$?
  set -e
  if [[ $rc -ne 0 || -z "$token" || "$token" == "null" ]]; then
    echo "Failed to obtain admin token. Check BASE_URL/REALM/admin creds." >&2
    return 1
  fi
  echo "$token"
}

find_user_id() {
  local username="$1"
  curl -sS -f -G "$API/users" \
    --data-urlencode "username=$username" \
    --data-urlencode "exact=true" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Accept: application/json' | jq -r '.[0].id // empty'
}

create_user() {
  local username="$1" email="$2"
  curl -sS -w '%{http_code}' -o /dev/stderr \
    -X POST "$API/users" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg u "$username" --arg e "$email" '{username:$u, email:$e, firstName: "Wandb", lastName: "User", enabled:true, emailVerified:true}')" >/tmp/kc_http_code
}

set_user_password() {
  local user_id="$1" password="$2"
  curl -sS -f -X PUT "$API/users/$user_id/reset-password" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg p "$password" '{type:"password", value:$p, temporary:false}')" >/dev/null
}

update_user_email() {
  local user_id="$1" email="$2"
  # Fetch current representation then merge email
  local current
  current=$(curl -sS -f "$API/users/$user_id" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Accept: application/json')
  local updated
  updated=$(jq --arg e "$email" '.email = $e | .emailVerified = false' <<<"$current")
  curl -sS -f -X PUT "$API/users/$user_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$updated" >/dev/null
}

find_client_id() {
  local cid="$1"
  curl -sS -f -G "$API/clients" --data-urlencode "clientId=$cid" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Accept: application/json' | jq -r '.[0].id // empty'
}

create_client() {
  local cid="$1"
  curl -sS -f -X POST "$API/clients" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg cid "$cid" '{
      clientId:$cid,
      protocol:"openid-connect",
      secret: "test-secret",
      enabled:true,
      publicClient:false,
      standardFlowEnabled:true,
      implicitFlowEnabled:true,
      redirectUris:["http://localhost:8080/*"],
      rootUrl:"http://localhost:8080",
      baseUrl:"http://localhost:8080",
      webOrigins:["*"]
    }')" >/dev/null
}

# Obtain admin token
log "Obtaining admin token from $TOKEN_URL as $ADMIN_USER (realm=$REALM)"
ACCESS_TOKEN=$(get_admin_token)
log "Admin token acquired"

# Ensure user exists and is configured
log "Ensuring user '$USERNAME' exists in realm '$REALM'"
USER_ID=$(find_user_id "$USERNAME" || true)
if [[ -z "$USER_ID" ]]; then
  log "User not found. Creating user '$USERNAME' with email '$EMAIL'"
  # Keycloak returns 201 with empty body; we need to fetch the ID afterward
  if ! create_user "$USERNAME" "$EMAIL"; then
    echo "Failed to create user" >&2
    exit 1
  fi
  # Retry fetch ID (user search is not always immediately consistent)
  for i in {1..10}; do
    sleep 0.5
    USER_ID=$(find_user_id "$USERNAME" || true)
    [[ -n "$USER_ID" ]] && break
  done
  if [[ -z "$USER_ID" ]]; then
    echo "Created user, but could not retrieve its ID" >&2
    exit 1
  fi
else
  log "User exists with id $USER_ID. Updating email to '$EMAIL'"
  update_user_email "$USER_ID" "$EMAIL"
fi

log "Setting password for user '$USERNAME'"
set_user_password "$USER_ID" "$PASSWORD"

# Ensure client exists
log "Ensuring client '$CLIENT_ID' exists in realm '$REALM'"
CLIENT_INTERNAL_ID=$(find_client_id "$CLIENT_ID" || true)
if [[ -z "$CLIENT_INTERNAL_ID" ]]; then
  log "Client not found. Creating client '$CLIENT_ID'"
  create_client "$CLIENT_ID"
  # Fetch again to confirm
  for i in {1..10}; do
    sleep 0.5
    CLIENT_INTERNAL_ID=$(find_client_id "$CLIENT_ID" || true)
    [[ -n "$CLIENT_INTERNAL_ID" ]] && break
  done
  if [[ -z "$CLIENT_INTERNAL_ID" ]]; then
    echo "Created client, but could not retrieve its ID" >&2
    exit 1
  fi
else
  log "Client exists with id $CLIENT_INTERNAL_ID"
fi

log "Done. User '$USERNAME' (id=$USER_ID) configured and client '$CLIENT_ID' (id=$CLIENT_INTERNAL_ID) ensured in realm '$REALM' at $BASE_URL."
