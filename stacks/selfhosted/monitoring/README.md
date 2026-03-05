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

## Alerting (Future Enhancement)

To add alerting capabilities:

1. Deploy Alertmanager:
   ```yaml
   # Add to compose.yaml
   alertmanager:
     image: prom/alertmanager:v0.27.0
     volumes:
       - ./alertmanager/config.yml:/etc/alertmanager/config.yml
   ```

2. Configure alert rules in Prometheus
3. Set up notification channels (Discord, Slack, Email, PagerDuty)

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
