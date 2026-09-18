# Selfhost Monitoring Stack

Unified observability platform for selfhost infrastructure, Home Assistant, and OpenClaw AI workloads.

## Stack Components

- **Prometheus** (v3.2.2): Time-series metrics database and scraping engine
- **Grafana** (v11.5.2): Visualization and dashboarding platform
- **cAdvisor** (v0.51.0): Container resource metrics collector
- **node-exporter** (v1.8.2): Host system metrics collector

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Prometheus                          │
│                 (Metrics Collection & Storage)              │
│                                                             │
│  Scrapes metrics from:                                      │
│  • 7 Exportarr instances (media automation metrics)         │
│  • Traefik (reverse proxy metrics)                          │
│  • cAdvisor (container CPU, RAM, network, disk)             │
│  • node-exporter (host CPU, RAM, disk, network)             │
│  • Future: Home Assistant (home automation metrics)         │
│  • Future: Cerebro VM (OpenClaw AI metrics)                 │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ PromQL queries
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                          Grafana                            │
│              (Dashboards & Visualization)                   │
│                                                             │
│  Dashboards:                                                │
│  • Traefik Overview (requests, latency, errors)             │
│  • Media Automation (downloads, queue, health)              │
│  • Container Metrics (per-container resource usage)         │
│  • Host System (CPU, RAM, disk, network)                    │
└─────────────────────────────────────────────────────────────┘
```

## Access URLs

- **Grafana**: https://grafana.deercrest.info
  - Default credentials: `admin` / `admin` (change on first login)
  - No Authelia required (Grafana has built-in auth)

- **Prometheus**: https://prometheus.deercrest.info
  - Protected by Authelia authentication
  - Direct PromQL query interface

- **cAdvisor**: https://cadvisor.deercrest.info
  - Protected by Authelia authentication
  - Container resource visualization

- **node-exporter**: Internal only (no web UI)
  - Metrics endpoint: `http://node-exporter:9100/metrics`

## Quick Start

### 1. Customize Environment

```bash
cd /mnt/fast/stacks/stacks/selfhosted/monitoring
cp .env.sample .env
nano .env  # Update GRAFANA_ADMIN_PASSWORD at minimum
```

### 2. Deploy Stack

```bash
cd /mnt/fast/stacks
docker compose -f stacks/selfhosted/monitoring/compose.yaml up -d
```

### 3. Verify Services

```bash
docker ps | grep -E "prometheus|grafana|cadvisor|node-exporter"

# Check Prometheus targets are healthy
docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job, health}'
```

### 4. Access Grafana

1. Navigate to https://grafana.deercrest.info
2. Login with default credentials (admin/admin)
3. Change admin password when prompted
4. Verify Prometheus datasource: Configuration → Data Sources → Prometheus

### 5. Import Dashboards

Grafana → Create → Import → Enter Dashboard ID:

**Recommended Community Dashboards:**

- **Traefik 2.0**: ID `17347`
  - Requests, latency, errors, status codes
  - https://grafana.com/grafana/dashboards/17347

- **Exportarr (Media Stack)**: ID `15709`
  - Sonarr, Radarr, Lidarr, Prowlarr, Bazarr metrics
  - Queue size, downloads, disk space, health
  - https://grafana.com/grafana/dashboards/15709

- **Docker Container Monitoring (cAdvisor)**: ID `11600`
  - Per-container CPU, RAM, network, disk I/O
  - https://grafana.com/grafana/dashboards/11600

- **Node Exporter Full**: ID `1860`
  - Host CPU, RAM, disk, network, filesystem
  - https://grafana.com/grafana/dashboards/1860

**Import Steps:**
1. Grafana → Dashboards → New → Import
2. Enter dashboard ID (e.g., `17347`)
3. Click "Load"
4. Select "Prometheus" datasource
5. Click "Import"

## Monitored Services

### Exportarr Instances (Already Deployed)
- `prowlarr-exporter:9707` - Indexer manager metrics
- `radarr-exporter:9707` - Movie automation metrics
- `sonarr-exporter:9707` - TV automation metrics
- `lidarr-exporter:9707` - Music automation metrics
- `readarr-exporter:9707` - Book automation metrics
- `bazarr-exporter:9707` - Subtitle automation metrics
- `sabnzbd-exporter:9707` - Download client metrics

### Infrastructure Components
- `traefik:8080` - Reverse proxy metrics
- `cadvisor:8080` - Container resource metrics
- `node-exporter:9100` - Host system metrics

### Future Integrations

**Home Assistant** (when ready):
```yaml
# Add to prometheus/prometheus.yml
- job_name: 'homeassistant'
  static_configs:
    - targets: ['homeassistant.local:8123']
  metrics_path: '/api/prometheus'
  bearer_token: 'YOUR_LONG_LIVED_ACCESS_TOKEN'
```

**Cerebro VM (OpenClaw)** (when node-exporter deployed):
```yaml
# Add to prometheus/prometheus.yml
- job_name: 'cerebro-node'
  static_configs:
    - targets: ['172.16.1.160:9100']
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      replacement: 'cerebro-vm102'
```

## Prometheus Configuration

### Scrape Interval
- Global: 15 seconds (balanced between freshness and load)
- Evaluation: 15 seconds (alerting rules evaluation)

### Data Retention
- Default: 30 days (configurable via `PROMETHEUS_RETENTION` in `.env`)
- Storage: `/mnt/fast/appdata/monitoring/prometheus`
- Estimated disk usage: ~5-10GB for 30 days

### Adding New Scrape Targets

Edit `prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-new-service'
    static_configs:
      - targets: ['service-name:port']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'friendly-name'
```

Then reload Prometheus:
```bash
docker exec prometheus kill -HUP 1
# Or restart the container
docker restart prometheus
```

## Resource Usage

| Service        | RAM Usage    | CPU Usage | Disk Usage      |
|----------------|--------------|-----------|-----------------|
| Prometheus     | 200-400 MB   | 1-3%      | 5-10 GB (30d)   |
| Grafana        | 100-200 MB   | 1-2%      | 500 MB          |
| cAdvisor       | 100-150 MB   | 2-5%      | Minimal         |
| node-exporter  | 10-20 MB     | <1%       | Minimal         |
| **Total**      | **~500 MB**  | **5-10%** | **6-11 GB**     |

## Troubleshooting

### Prometheus Target Down

```bash
# Check Prometheus logs
docker logs prometheus

# Verify target is reachable from Prometheus container
docker exec prometheus wget -qO- http://target-container:port/metrics

# Check network connectivity
docker exec prometheus ping target-container
```

### Grafana Datasource Not Working

```bash
# Check Grafana logs
docker logs grafana

# Verify Prometheus is reachable from Grafana
docker exec grafana wget -qO- http://prometheus:9090/api/v1/status/config

# Re-provision datasource
docker restart grafana
```

### Missing Metrics

```bash
# List all available metrics in Prometheus
docker exec prometheus wget -qO- 'http://localhost:9090/api/v1/label/__name__/values' | jq

# Check specific exporter is exposing metrics
docker exec radarr-exporter wget -qO- http://localhost:9707/metrics | grep radarr
```

### High Memory Usage

```bash
# Reduce Prometheus retention
# Edit .env: PROMETHEUS_RETENTION=7d
docker compose -f stacks/selfhosted/monitoring/compose.yaml down
docker compose -f stacks/selfhosted/monitoring/compose.yaml up -d

# Disable high-cardinality metrics in cAdvisor
# Already configured with --disable_metrics flag
```

## Alerting

> **Superseded 2026-09-18.** This section used to propose deploying Alertmanager and filling
> Prometheus's `alerting:` block. **Do neither.** The estate alerts through **Grafana's own unified
> alerting**, which is already running, straight to **Telegram** (D-02). `prometheus/prometheus.yml`
> is deliberately left exactly as it is — node-exporter is already a scrape target, so the metrics
> below arrive with no scrape-config change at all.

Provisioned from three files, all read by Grafana at start-up from
`grafana/provisioning/alerting/` (a **directory** mount, unlike the two single-file provisioning
mounts):

| File | What it declares |
|------|------------------|
| `contact-points.yaml` | the `telegram-estate` receiver — **token and chat id as `$__env{}` placeholders only** |
| `notification-policies.yaml` | one default route to that receiver, `repeat_interval: 12h` |
| `rules.yaml` | the three rules below, all `noDataState: Alerting` |

## Image drift detection

**The question this answers:** *which containers are running an image that git no longer pins?*

Renovate automerges image-tag PRs into this repo at any hour and **nothing deploys** — the host
keeps running the old image until someone pulls and recreates the container. On 2026-09-18, **14 of
the ~97 running containers were diverged and no instrument anywhere said so.**

**v1 is ALERT-ONLY (D-01). It detects and tells you. It does not pull, recreate or apply anything.**

### The instrument

`scripts/check-drift.sh`, run **on LXC 100**:

```bash
ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-drift.sh'        # human report
ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-drift.sh --prom' # write the metric
bash /mnt/fast/stacks/scripts/check-drift.sh --help                        # the full contract
```

It resolves each container's declared pin through **that container's own compose labels** plus
`docker compose config --format json`, so `include:` and `${VAR}` substitution both resolve and
commented-out `image:` lines never enter the pin map. Keying per container rather than per image
repo is what makes it correct: `socket-proxy` runs `v0.4.2` and the traefik project pins `v0.5.0`,
while `stacks/mpe/edge/socket-proxy.yaml` *also* carries `v0.4.2` — a repo-wide search calls that
clean, and it is not.

### The metrics

Written atomically into `/mnt/fast/appdata/monitoring/node-exporter-textfile/image-drift.prom` and
picked up by node-exporter's textfile collector.

| Metric | Meaning |
|--------|---------|
| `selfhost_image_drift_containers` | count of running containers on a tag git no longer pins |
| `selfhost_image_drift_unresolvable_containers` | pins that cannot be read from the repo at all |
| `selfhost_image_drift_container{name,running,declared}` | one series per drifted container |
| `selfhost_containers_unhealthy` | docker health status `unhealthy` |
| `selfhost_containers_created` | stuck in state `created` — the documented blind spot |
| `selfhost_repo_commits_behind_origin` | **lower bound**, see limits below |
| `selfhost_image_drift_last_success_timestamp_seconds` | when the measurement last **ran** |

> ⚠️ `last_success` means **the measurement ran**. It does **not** mean there is no drift — drift
> has its own gauge. It is written **only** on a successful run; on a could-not-look the existing
> file is left **byte-identical** so it goes stale and the staleness rule fires. A fresh timestamp
> on a failed run is the one outcome this metric exists to prevent.

### ⚠️ The timer period and the staleness threshold are ONE decision

`OnCalendar=hourly` + `RandomizedDelaySec=10m` means two healthy runs land **at most 70 minutes
apart**, so `rules.yaml` uses **7200s** — one whole missed run of slack. A threshold *below* the
period false-alarms on every ordinary gap; a threshold *far above* it hides a dead timer, which is
the exact failure the metric exists to catch. **Change one and you must change the other in the
same commit.** Both files say so.

### Two known limits — stated because they make a green weaker than it reads

1. **A floating tag that has moved upstream reads as no drift.** `:latest`, `:main` and two-part
   tags like `2.13` all float: the registry re-points them, both sides of the comparison still
   carry the same string, and the check says OK. This is DEPLOYMENT.md § 5's "two-part tags float"
   trap in a new costume. Not fixed in v1 — fixing it means resolving digests against the registry,
   a network dependency and rate-limit surface this check deliberately does not take on.
2. **`commits behind` is a lower bound without a fetch.** It reads the last-fetched `origin/main`.
   `DRIFT_GIT_FETCH=1` fetches first; it is **off by default** because a timer that mutates `.git`
   hourly is a host change nobody asked for.

### ⛔ Gated host steps — NOT EXECUTED BY THIS CHANGE

Everything above is a **repo-side declaration**. Nothing in the commit that added it touched the
estate: no directory created, no container recreated, no unit installed, no credential supplied.
The four steps below are the runbook, and they are waiting on an explicit decision.

#### G0 — pull on the host · **NOT EXECUTED BY THIS CHANGE** · ⚠️ read this one first

> ⚠️ **From the moment this change is merged, `scripts/quick-health-check.sh` exits 1 until the
> host has pulled.** That is the fold-in failing closed, exactly as designed — `check-drift.sh`
> only reaches `/mnt/fast/stacks` by git, and a check that cannot find its subject reports
> `UNKNOWN` rather than skipping. The block says so in as many words:
> `⚠️ UNKNOWN — /mnt/fast/stacks/scripts/check-drift.sh is NOT ON THE HOST.`
>
> It is called out here because it is the one effect of this change that reaches someone who did
> not ask for it: anybody running the estate health check between the merge and the pull.

```bash
ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only'
bash scripts/quick-health-check.sh    # from the workstation — back to 0, drift count printed
```

G0 alone restores the health check and gives you the report on demand. **G1–G3 are what make it
run unattended**, and G4 is what makes it able to tell you.

#### G1 — create the textfile directory · **NOT EXECUTED BY THIS CHANGE**

```bash
ssh root@172.16.1.159
install -d -o 568 -g 568 -m 0755 /mnt/fast/appdata/monitoring/node-exporter-textfile
```

#### G2 — pull and recreate node-exporter + grafana · **NOT EXECUTED BY THIS CHANGE**

> ⚠️ **This recreates two running containers.**

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks && git pull --ff-only
docker compose -f stacks/selfhosted/monitoring/compose.yaml up -d node-exporter grafana
```

> **`node-exporter` is itself one of the drifted containers** (running `v1.11.1`, pinned
> `v1.12.1`), so this step takes the count **14 → 13**. That is the change working, not a
> regression. Record it; do not read a smaller number as a fault.

#### G3 — install and enable the timer · **NOT EXECUTED BY THIS CHANGE**

```bash
ssh root@172.16.1.159
cp /mnt/fast/stacks/scripts/systemd/selfhost-image-drift.{service,timer} /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now selfhost-image-drift.timer
systemctl list-timers selfhost-image-drift.timer      # confirm it is scheduled
systemctl start selfhost-image-drift.service          # one immediate run
ls -l /mnt/fast/appdata/monitoring/node-exporter-textfile/image-drift.prom
```

#### G4 — supply the Telegram credentials **and prove delivery** · **NOT EXECUTED BY THIS CHANGE**

The bot does not exist yet. Telegram bots cannot initiate a conversation, so the chat id only
exists after you message it once.

1. Telegram → **@BotFather** → `/newbot` → copy the HTTP API token
2. Send the new bot one message
3. `GET https://api.telegram.org/bot<TOKEN>/getUpdates` → `result[].message.chat.id`
4. Store both in `~/.claude/secrets/` — **never in this repo, which is public** (D-04)
5. Put them in `stacks/selfhosted/monitoring/.env` (gitignored) as `TELEGRAM_BOT_TOKEN=` and
   `TELEGRAM_CHAT_ID=`, then recreate Grafana
6. **Grafana → Alerting → Contact points → `telegram-estate` → Test → confirm a message actually
   arrives on the phone**

> ⚠️ **Until step 6 has produced a received message, the alert path is UNPROVEN and must not be
> counted as coverage.** `grafana.yaml` uses `${TELEGRAM_BOT_TOKEN:-}` rather than `:?` so the
> stack still parses without the secrets — the cost is that an **empty token means the contact
> point exists, the rule fires, and the message goes nowhere**, which looks identical to a healthy
> estate. Phase 2 closed on exactly that shape of notification path, and an unproven channel is
> worse than a known-manual check because it *feels* covered.

### What will fire first, and why it is not a misconfiguration

`Containers unhealthy or stuck created` will alert as soon as G1–G3 land: on 2026-09-18 `cadvisor`
reported health `unhealthy`. Note that **`docker ps` showed it `Up 2 weeks (health: starting)`
while `docker inspect` on the same container id showed `exited`, code 137, finished 2026-09-02** —
sixteen days dead behind a `docker ps` line that said it was up. Believe `inspect`.

## Backup

Critical files to backup:
- `/mnt/fast/appdata/monitoring/grafana/grafana.db` - Dashboards and settings
- `/mnt/fast/appdata/monitoring/prometheus/` - Metrics data (optional)
- `stacks/selfhosted/monitoring/.env` - Configuration

Grafana dashboards can also be exported as JSON from the UI.

## Maintenance

### Update Stack

```bash
cd /mnt/fast/stacks
git pull
docker compose -f stacks/selfhosted/monitoring/compose.yaml pull
docker compose -f stacks/selfhosted/monitoring/compose.yaml up -d
```

### View Logs

```bash
docker compose -f stacks/selfhosted/monitoring/compose.yaml logs -f
```

### Restart Stack

```bash
docker compose -f stacks/selfhosted/monitoring/compose.yaml restart
```

### Stop Stack

```bash
docker compose -f stacks/selfhosted/monitoring/compose.yaml down
```

## Security Notes

- Prometheus and cAdvisor are protected by Authelia (SSO authentication)
- Grafana uses its own authentication system
- **Change default Grafana password immediately** after first login
- Consider enabling Grafana LDAP/OAuth if available
- All services exposed via HTTPS through Traefik with Let's Encrypt certificates

## Support

For issues or questions:
1. Check container logs: `docker logs <container-name>`
2. Verify Prometheus targets: https://prometheus.deercrest.info/targets
3. Check Grafana datasource: Grafana → Configuration → Data Sources
4. Review this README troubleshooting section

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [cAdvisor GitHub](https://github.com/google/cadvisor)
- [node-exporter GitHub](https://github.com/prometheus/node_exporter)
- [Exportarr GitHub](https://github.com/onedr0p/exportarr)
