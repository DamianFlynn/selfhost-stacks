# Traefik dynamic rules (file provider)

These four files are the **shared middleware, chain and TLS definitions** that gate every
service in the estate. `chain-authelia@file` alone is referenced by ~49 stack files.

## ⚠️ This directory is a MIRROR, not the deployment source

Traefik reads these from the host, not from this repo:

```
/mnt/fast/appdata/traefik/rules   ->  /rules   (bind mount, see traefik.yaml)
```

So **committing a change here deploys nothing.** The host copy is authoritative and is
hot-reloaded by the file provider within seconds of being written. Editing only the repo copy
produces a silent no-op — the same deploy-drift trap documented in README § Renovate deploy
drift, and the reason a "green" health check can be measured against config that was never
applied.

To change a rule: edit the file on the host, confirm `docker logs traefik` shows a clean
reload with no `error` lines, verify the behaviour, **then** copy the file here and commit.

Brought under version control 2026-09-27. Before that the chain that fronts every service in
the estate existed in exactly one place, on one disk, untracked and unrecoverable.

## Files

| File | Purpose |
|---|---|
| `middleware.yml` | `default-headers`, `secure-headers`, `authelia` forwardAuth, and the `chain-*` chains |
| `tls.yml` | TLS options and cipher suites |
| `app-fpp-no-auth.yml` | Per-app override: FPP bypasses Authelia |
| `app-haos-no-auth.yml` | Per-app override: HAOS bypasses Authelia |

## The `buffering` middleware was removed 2026-09-27 — do not reinstate

`middleware.yml` carries the full reasoning and the measurements inline. The short version:
it was added to "fix 431 errors", which it cannot do (a 431 is a *request header* error;
`buffering` only caps *bodies*), and its `maxResponseBodyBytes: 10485760` made Traefik hold
every response in full before forwarding a byte — silently breaking every download and stream
over 10 MB on all ~49 routers using `chain-authelia`.

Read that comment before touching this chain.
