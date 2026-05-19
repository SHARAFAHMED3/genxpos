#!/usr/bin/env bash
# Build .env from .env.example using environment variables (CI/CD secrets).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${ENV_TEMPLATE:-${ROOT_DIR}/.env.example}"
ENV_FILE="${ENV_OUTPUT:-${ROOT_DIR}/.env}"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Missing template: $TEMPLATE" >&2
  exit 1
fi

cp "$TEMPLATE" "$ENV_FILE"

# Keys populated from GitHub Actions / server environment when set.
ENV_KEYS=(
  APP_NAME
  APP_TITLE
  APP_ENV
  APP_KEY
  APP_DEBUG
  APP_URL
  APP_LOCALE
  APP_TIMEZONE
  ADMINISTRATOR_USERNAMES
  ALLOW_REGISTRATION
  DB_CONNECTION
  DB_HOST
  DB_PORT
  DB_DATABASE
  DB_USERNAME
  DB_PASSWORD
  MAIL_MAILER
  MAIL_HOST
  MAIL_PORT
  MAIL_USERNAME
  MAIL_PASSWORD
  MAIL_ENCRYPTION
  MAIL_FROM_ADDRESS
  MAIL_FROM_NAME
  ENVATO_PURCHASE_CODE
  MAC_LICENCE_CODE
)

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

format_value() {
  local val="$1"
  if [[ "$val" =~ [[:space:]] ]]; then
    printf '"%s"' "$val"
  else
    printf '%s' "$val"
  fi
}

set_env() {
  local key="$1"
  local val="${2:-}"
  if [[ -z "$val" ]]; then
    return 0
  fi

  local formatted escaped
  formatted="$(format_value "$val")"
  escaped="$(escape_sed "$formatted")"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${escaped}|" "$ENV_FILE"
  else
    echo "${key}=${formatted}" >>"$ENV_FILE"
  fi
}

for key in "${ENV_KEYS[@]}"; do
  if [[ -n "${!key:-}" ]]; then
    set_env "$key" "${!key}"
  fi
done

chmod 640 "$ENV_FILE" 2>/dev/null || chmod 600 "$ENV_FILE" 2>/dev/null || true
echo "Wrote ${ENV_FILE}"
