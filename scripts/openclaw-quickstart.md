# OpenClaw Quick Start Guide

## LXC 101 (openclaw) - 172.16.1.160

### Current Setup
- **OpenClaw Version**: 2026.2.14
- **Ollama**: Running locally on same LXC (127.0.0.1:11434)
- **Gateway Port**: 18789
- **Gateway Token**: `Atlant1s!`

### Available Models
- `qwen2.5-coder:3b` (default)
- `llama3.2:latest`

### Access URLs

**Web UI (from local network)**:
```
http://172.16.1.160:18789/#token=Atlant1s!
```

**SSH Tunnel (from macOS)**:
```bash
ssh -N -L 18789:127.0.0.1:18789 root@172.16.1.160
```
Then open: `http://localhost:18789/#token=Atlant1s!`

### Management Commands

#### Using the setup script (from macOS):
```bash
cd /Users/damian/Development/damianflynn/selfhost-stacks

# Check status
./scripts/setup-openclaw.sh status

# Start gateway
./scripts/setup-openclaw.sh start

# Stop gateway
./scripts/setup-openclaw.sh stop

# Restart gateway
./scripts/setup-openclaw.sh restart

# Full setup (configure + start)
./scripts/setup-openclaw.sh full-setup
```

#### Direct commands (SSH into LXC):
```bash
ssh root@172.16.1.160

# Check OpenClaw version
openclaw --version

# Check gateway status
ps aux | grep openclaw

# View logs
tail -f /tmp/openclaw-gateway.log

# Start gateway manually (accessible from network)
nohup openclaw gateway --bind lan --token Atlant1s! > /tmp/openclaw-gateway.log 2>&1 &

# Start gateway (localhost only)
nohup openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &

# Stop gateway
pkill -f 'openclaw-gateway'

# Test Ollama connectivity
curl http://127.0.0.1:11434/api/tags

# List models
ollama list
```

### Configuration File
```bash
# Location
/root/.openclaw/openclaw.json

# Backup
cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup

# View current config
cat /root/.openclaw/openclaw.json
```

### Current Configuration
```json
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "auth": {
      "token": "Atlant1s!"
    }
  }
}
```

**Note**: Bind mode (`lan` for network access) is specified via command line flag `--bind lan` when starting the gateway, not in the config file.

### Adding New Models

```bash
ssh root@172.16.1.160

# Pull a new model
ollama pull qwen2.5-coder:14b

# List available models
ollama list

# Update default model in config
nano /root/.openclaw/openclaw.json
# Change: "default": "ollama/qwen2.5-coder:14b"

# Restart gateway
pkill -f 'openclaw gateway'
nohup openclaw gateway start > /tmp/openclaw-gateway.log 2>&1 &
```

### Troubleshooting

#### Gateway won't start
```bash
# Check if already running
ps aux | grep openclaw

# Check logs
tail -50 /tmp/openclaw-gateway.log

# Check Ollama connectivity
curl http://127.0.0.1:11434/api/tags

# Kill existing process and restart (with network access)
pkill -f 'openclaw-gateway'
sleep 2
nohup openclaw gateway --bind lan --token Atlant1s! > /tmp/openclaw-gateway.log 2>&1 &
```

#### Cannot access web UI from network
```bash
# Check if gateway is bound to correct interface
ss -tlnp | grep 18789

# Should show 0.0.0.0:18789 (not 127.0.0.1:18789)
# If showing 127.0.0.1, gateway started without --bind lan flag

# Restart with --bind lan
pkill -f 'openclaw-gateway'
nohup openclaw gateway --bind lan --token Atlant1s! > /tmp/openclaw-gateway.log 2>&1 &
```

#### Model not found
```bash
# List available models
ollama list

# Update config to use available model
nano /root/.openclaw/openclaw.json
```

#### Cannot access web UI
```bash
# Check gateway is running
ps aux | grep openclaw

# Check port is listening
netstat -tlnp | grep 18789

# From macOS, create SSH tunnel
ssh -N -L 18789:127.0.0.1:18789 root@172.16.1.160
```

### Important Notes

1. **Systemd not available**: LXC 101 is unprivileged, systemd user services won't work
2. **Manual start required**: Gateway must be started manually or via supervisor
3. **Local Ollama**: Ollama runs on same LXC (not on LXC 100)
4. **No GPU**: LXC 101 doesn't have GPU passthrough (use smaller models)

### Recommended Models for LXC 101

Since LXC 101 doesn't have GPU acceleration, use smaller quantized models:
- `qwen2.5-coder:3b` (1.9 GB) ✅ Currently installed
- `llama3.2:latest` (2.0 GB) ✅ Currently installed
- `phi3:mini` (2.2 GB)
- `gemma2:2b` (1.6 GB)

Avoid large models without GPU:
- ❌ `qwen2.5-coder:14b` (8.9 GB) - Too slow without GPU
- ❌ `llama3.3:70b` (40 GB) - Won't fit in memory

### Next Steps

1. **Access the Web UI**: http://172.16.1.160:18789/#token=Atlant1s!
2. **Test a conversation**: Ask OpenClaw to help with a coding task
3. **Enable skills**: `openclaw configure --section skills`
4. **Setup channels**: Configure Telegram/Discord for remote access

### Documentation
- OpenClaw Docs: https://docs.openclaw.ai/
- Gateway Security: https://docs.openclaw.ai/gateway/security
- Skills Reference: https://docs.openclaw.ai/skills/
