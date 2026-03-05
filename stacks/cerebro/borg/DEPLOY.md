# LXC 101 Quick Deploy

Target host: `root@172.16.1.160`

## Paths

- Stacks repo: `/mnt/fast/stacks/selfhost-stacks`
- Appdata root: `/mnt/fast/appdata`
- Borg stack: `/mnt/fast/stacks/borg`

## Borg stack (includes workloads)

```bash
ssh root@172.16.1.160
cd /mnt/fast/stacks/borg
docker compose -f compose.yaml up -d
docker compose -f compose.yaml ps
```

Included files:

- `ollama.yaml`
- `demo-workload.yaml`

## Quick checks

```bash
ssh root@172.16.1.160
docker logs --tail=100 ollama-gpu-test
docker exec ollama-gpu-test ollama ps
curl -s http://127.0.0.1:18080
```

## Replace demo with real workload

1. Edit `/mnt/fast/stacks/borg/demo-workload.yaml`
2. Update app data under `/mnt/fast/appdata/demo-workload`
3. Redeploy:

```bash
ssh root@172.16.1.160
cd /mnt/fast/stacks/borg
docker compose -f compose.yaml up -d --force-recreate
```

## Useful checks

```bash
ssh root@172.16.1.160 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
ssh root@172.16.1.160 'ls -la /mnt/fast/stacks /mnt/fast/appdata'
```
