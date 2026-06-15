# MPE ERPNext (frappe_docker, v16)

ERPNext is the **operational master** for MPE Renewables (products, stock, orders,
invoices). It pushes to WooCommerce (shop) and Xero (accounts) via n8n. Pinned to
**ERPNext v16** (GA since Jan 2026; latest stable at authoring = `v16.22.0`).

This directory holds only the **overlay** (`compose.override.yaml` + `.env`). The
upstream compose files are cloned at deploy time so Renovate/upstream fixes stay
trackable separately.

## Deploy (run inside LXC 102 "mpe", from `/mnt/fast/stacks/stacks/mpe/erpnext`)

```bash
# 1. Clone upstream frappe_docker into this directory (kept out of git).
git clone https://github.com/frappe/frappe_docker.git frappe_docker

# 2. Configure env.
cp .env.sample .env && $EDITOR .env     # set ERPNEXT_VERSION, DB_PASSWORD, ADMIN_PASSWORD

# 3. Define the compose layer set once (upstream base + mariadb + redis + our override).
export COMPOSE_FILE="frappe_docker/compose.yaml:\
frappe_docker/overrides/compose.mariadb.yaml:\
frappe_docker/overrides/compose.redis.yaml:\
compose.override.yaml"

# 4. Sanity-check the merged config (verify volume names match the override).
docker compose --env-file .env config --volumes
docker compose --env-file .env config | grep -A3 'mpe-erp'   # confirm Traefik labels

# 5. Bring up data + app tiers.
docker compose --env-file .env up -d

# 6. Create the site + install ERPNext (one-time).
docker compose --env-file .env exec backend \
  bench new-site "$SITE_NAME" \
  --mariadb-root-password "$DB_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --install-app erpnext

# 7. Set the public host_name so links/emails use the tunnel URL.
docker compose --env-file .env exec backend \
  bench --site "$SITE_NAME" set-config host_name "https://mpe-erp.diginerve.net"
```

> `.gitignore` already ignores `**/.env`. Add `frappe_docker/` to the repo
> `.gitignore` (or a local one) so the upstream clone is not committed.

## Routing

`compose.override.yaml` labels the `frontend` service for
`Host(mpe-erp.diginerve.net)` on Traefik's **HTTP `web`** entrypoint. Public TLS
is terminated at the Cloudflare edge and carried over the tunnel (cert approach
"a" — no Let's Encrypt / CF token inside MPE Traefik).

## Data import (after stand-up)

Item groups, warehouses and the 1,908-item master come from
`agent-os/.../resources/product-master-xref-2026-06-15.csv` via **Data Import**.
Do **not** import quantities — leave on-hand at 0 until the physical count.
Full sequence: `phase-2-erpnext-deployment.md` → "Rapid operational config".

## Verify

```bash
docker compose --env-file .env exec backend bench doctor          # background jobs
docker compose --env-file .env exec backend bench --site "$SITE_NAME" backup
curl -H 'Host: mpe-erp.diginerve.net' http://mpe-traefik/api/method/ping   # via edge
```
