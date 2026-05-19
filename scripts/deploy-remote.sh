#!/usr/bin/env bash
# Post-deploy steps on CyberPanel (run over SSH after rsync).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# CyberPanel genxpos subdomain uses PHP 8.2; override with PHP_BIN if needed.
PHP_BIN="${PHP_BIN:-php}"
COMPOSER_BIN="${COMPOSER_BIN:-composer}"

if [[ ! -f .env ]]; then
  echo "Missing .env — run scripts/generate-env.sh first." >&2
  exit 1
fi

$PHP_BIN artisan down --retry=60 || true

if command -v "$COMPOSER_BIN" >/dev/null 2>&1; then
  $COMPOSER_BIN install --no-dev --optimize-autoloader --no-interaction --prefer-dist
else
  echo "Composer not found; skipping vendor install." >&2
fi

$PHP_BIN artisan migrate --force

$PHP_BIN artisan config:cache
$PHP_BIN artisan route:cache
$PHP_BIN artisan view:cache

if [[ ! -L public/storage ]]; then
  $PHP_BIN artisan storage:link 2>/dev/null || true
fi

chmod -R ug+rwx storage bootstrap/cache 2>/dev/null || true

$PHP_BIN artisan up

echo "Deploy finished at ${ROOT_DIR}"
