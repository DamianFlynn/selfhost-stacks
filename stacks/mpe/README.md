# MPE Renewables — dedicated stack (LXC 102 "mpe")

Fully isolated environment for MPE Renewables "Project Volta" (ERPNext replacing
MRPeasy, via **parallel build + controlled cutover**). Nothing here is shared
with the personal stack (LXC 100 "selfhost" @ 172.16.1.159) — own LXC, own
Traefik, own tunnel, own backups.

Full project context lives in the agent-os vault:
`Projects/customers/MPE/volta-digital-foundation/` (see `implementation/
phase-2-erpnext-deployment.md` for the BOM + deploy sequence and operational config).

## Topology

```
Internet
  │  TLS (Cloudflare edge cert)
Cloudflare edge
  │  Cloudflare Tunnel (outbound from LXC 102 — no port-forward, no public IP)
mpe-cloudflared
  │  http://mpe-traefik:80   (plain HTTP inside the LXC)
mpe-traefik ──► mpe-erp.diginerve.net  → ERPNext frontend
            ──► mpe-n8n.diginerve.net  → n8n
            ──► mpe-shop.diginerve.net → WordPress/WooCommerce (later)
```

> **Naming:** flat `mpe-*.diginerve.net` (NOT `*.mpe.diginerve.net`) so the hosts
> are covered free by the existing `*.diginerve.net` Cloudflare Universal SSL —
> no paid Advanced Certificate Manager needed.

## Locked decisions (2026-06-15, confirmed)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Sizing / IP | 20 GB RAM / 8 cores / 100 GB disk; **172.16.1.163** (LXC 102) |
| 2 | Certs | **(a)** Cloudflare edge certs via the tunnel — **no CF token in MPE Traefik**, no Let's Encrypt here |
| 3 | n8n image | reuse `ghcr.io/damianflynn/custom-n8n` |
| 4 | Authelia | **deferred** for PoC; Google OAuth SSO planned later (see below) |
| 5 | ERPNext version | **v16** (GA; pinned `v16.22.0`) |
| 6 | Cloudflare | tunnel + flat `mpe-{erp,n8n,shop}.diginerve.net` DNS created via `scripts/setup-mpe-cloudflare.sh` |
| 7 | Hostnames | **flat** `mpe-*.diginerve.net` (free Universal SSL) — NOT `*.mpe.diginerve.net` (would need paid ACM) |

> **Secrets** live in per-stack gitignored `.env` files (and generated values),
> matching this repo's convention — **not** in "Keeper" (that's a calendar
> sync service on the personal stack, not a secret store).

## Layout

```
stacks/mpe/
├── edge/        Traefik + cloudflared + socket-proxy (owns mpe_proxy network)
├── erpnext/     frappe_docker v16 overlay (compose.override + .env + README)
└── n8n/         MPE's own n8n + Postgres (integration spine)
infra/lxc-mpe.tf  Proxmox LXC 102 provisioning (clone-in-spirit of lxc-selfhost.tf)
scripts/setup-mpe.sh             host dir tree + .env scaffolding + secret gen
scripts/setup-mpe-cloudflare.sh  create tunnel + DNS, emit TUNNEL_TOKEN
```

## Deploy order (apply nothing until reviewed)

1. **Provision LXC 102** — `cd infra && terraform plan` (review the NET-NEW
   resources), then `terraform apply`. Requires `mpe_root_password` in
   `terraform.tfvars`. Creates the LXC, the `fast/appdata/mpe` dataset, installs
   Docker CE, apps:apps.
2. **Host prep** (inside LXC 102) — `bash scripts/setup-mpe.sh` (dirs + .env +
   secrets).
3. **Cloudflare** — `scripts/setup-mpe-cloudflare.sh` (needs `CF_API_TOKEN` +
   account/zone ids); paste the emitted `TUNNEL_TOKEN` into `edge/.env`.
4. **Edge** — `docker compose -f stacks/mpe/edge/compose.yaml up -d`.
5. **n8n** — `docker compose -f stacks/mpe/n8n/compose.yaml up -d`.
6. **ERPNext** — follow `erpnext/README.md` (clone frappe_docker, bench new-site).

## TLS coverage (resolved)

Hosts use **flat `mpe-*.diginerve.net`** naming so they are covered free by the
existing `*.diginerve.net` Cloudflare **Universal SSL** — **no ACM cost**.
(Third-level `*.mpe.diginerve.net` would have needed paid Advanced Certificate
Manager / Total TLS, ~$10/mo. Avoided.)

If you ever want `*.mpe.diginerve.net` instead: enable ACM on the zone, then set
`DOMAINNAME=mpe.diginerve.net`, `HOSTS="erp n8n shop"`, and revert the Traefik
`Host(...)` labels.

## SSO plan (post-PoC)

Authelia is deferred. Target: **Google OAuth (OIDC)** SSO for ERPNext,
WordPress/WooCommerce and n8n. Likely Authelia-as-OIDC-broker (Google upstream)
or `oauth2-proxy` forward-auth wired into the `mpe-chain-sso@file` middleware
placeholder in `edge/rules/middlewares.yml`. Until then admin UIs ride on the
no-auth chain behind the tunnel — **lock down before live Xero/Woo credentials
are stored in n8n.**

## MCP layer (later)

A WooCommerce/WordPress MCP will let Claude: (1) apply MPE branding to the new
WP/Woo, (2) scrape + consolidate the two legacy sites
(mpe-online.ie + mperenewables.ie), (3) map the live WooCommerce catalogue to the
**Manager.io** inventory (the current product source-of-truth, no reliable stock
counts) so the new shop is repopulated **from ERPNext** with correct data +
product graphics. Deferred until the spine + branded WP/Woo are up.

## Parallel-run safety

New WooCommerce runs **Stripe TEST mode**; ERPNext→Xero uses a **Demo org** until
cutover. No writes to live MRPeasy / live WooCommerce while proving.
