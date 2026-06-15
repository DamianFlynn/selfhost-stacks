#!/usr/bin/env bash
# setup-mpe.sh — host-side prep for the MPE stack (run inside LXC 102 "mpe").
#
# Creates the appdata directory tree under the dedicated dataset and scaffolds
# .env files from samples with freshly generated secrets. Idempotent: existing
# .env files are never overwritten.
#
# Run from the repo root on the host: bash scripts/setup-mpe.sh
set -euo pipefail

APPDATA="/mnt/fast/appdata/mpe"
STACKS="$(cd "$(dirname "$0")/.." && pwd)/stacks/mpe"
UIDGID="568:568"

echo "==> Creating appdata tree under ${APPDATA}..."
mkdir -p \
  "${APPDATA}/edge/traefik/rules" \
  "${APPDATA}/edge/traefik/logs" \
  "${APPDATA}/n8n/n8n-home" "${APPDATA}/n8n/n8n" "${APPDATA}/n8n/cache" \
  "${APPDATA}/n8n/local-files" "${APPDATA}/n8n/n8n-postgres" \
  "${APPDATA}/erpnext/sites" "${APPDATA}/erpnext/db" "${APPDATA}/erpnext/redis-queue"

echo "==> Seeding Traefik dynamic rules..."
cp -n "${STACKS}/edge/rules/middlewares.yml" "${APPDATA}/edge/traefik/rules/middlewares.yml"

echo "==> Setting ownership ${UIDGID}..."
chown -R "${UIDGID}" "${APPDATA}"

gen()    { openssl rand -base64 24 | tr -d '\n'; }
genhex() { openssl rand -hex 32 | tr -d '\n'; }

seed_env() { # $1=stack dir
  local d="$1"
  if [[ -f "${d}/.env" ]]; then
    echo "    ${d}/.env exists — leaving untouched"
  else
    cp "${d}/.env.sample" "${d}/.env"
    echo "    created ${d}/.env from sample"
  fi
}

echo "==> Scaffolding .env files..."
seed_env "${STACKS}/edge"
seed_env "${STACKS}/n8n"
seed_env "${STACKS}/erpnext"

echo "==> Suggested generated secrets (paste into the matching .env, then discard):"
echo "    n8n      N8N_ENCRYPTION_KEY=$(genhex)"
echo "    n8n      N8N_DB_PASSWORD=$(gen)"
echo "    erpnext  DB_PASSWORD=$(gen)"
echo "    erpnext  ADMIN_PASSWORD=$(gen)"
echo
echo "Next:"
echo "  1. Fill secrets above into stacks/mpe/{n8n,erpnext}/.env"
echo "  2. Create the tunnel:  scripts/setup-mpe-cloudflare.sh  (sets edge/.env TUNNEL_TOKEN)"
echo "  3. Bring up edge:      docker compose -f stacks/mpe/edge/compose.yaml up -d"
echo "  4. Bring up n8n:       docker compose -f stacks/mpe/n8n/compose.yaml up -d"
echo "  5. ERPNext:            see stacks/mpe/erpnext/README.md"
