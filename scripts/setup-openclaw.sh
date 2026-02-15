#!/usr/bin/env bash
#
# OpenClaw Setup Script for LXC 101 (openclaw)
# Configures OpenClaw to use Ollama running locally on the same LXC
#
# Note: LXC 101 is unprivileged - systemd user services not available
#       Gateway must be started manually or via supervisor
#
# Usage:
#   ./setup-openclaw.sh [--start|--stop|--status|--configure]
#

set -euo pipefail

OPENCLAW_LXC="172.16.1.160"
OLLAMA_HOST="127.0.0.1:11434"  # Local Ollama on same LXC
GATEWAY_PORT="18789"
GATEWAY_TOKEN="Atlant1s!"
OPENCLAW_CONFIG="/root/.openclaw/openclaw.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if running from macOS or directly on LXC
if [[ "$(uname)" == "Darwin" ]]; then
    SSH_PREFIX="ssh root@${OPENCLAW_LXC}"
else
    SSH_PREFIX=""
fi

run_cmd() {
    if [[ -n "${SSH_PREFIX}" ]]; then
        ${SSH_PREFIX} "$*"
    else
        bash -c "$*"
    fi
}

configure_ollama() {
    log_info "Configuring OpenClaw to use local Ollama at ${OLLAMA_HOST}..."
    
    # Update openclaw.json to use local Ollama
    cat <<EOF | run_cmd "tee ${OPENCLAW_CONFIG}.new > /dev/null"
{
  "version": "2026.2",
  "gateway": {
    "port": ${GATEWAY_PORT},
    "bind": "0.0.0.0",
    "auth": {
      "type": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "models": {
    "providers": {
      "ollama": {
        "base_url": "http://${OLLAMA_HOST}/v1",
        "api_key": "not-required"
      }
    },
    "default": "ollama/qwen2.5-coder:3b"
  },
  "agent": {
    "workspace": "/root/.openclaw/workspace",
    "tools_enabled": true,
    "hooks": {
      "enabled": ["command-logger", "session-memory"]
    }
  },
  "channels": {}
}
EOF

    run_cmd "cp ${OPENCLAW_CONFIG} ${OPENCLAW_CONFIG}.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true"
    run_cmd "mv ${OPENCLAW_CONFIG}.new ${OPENCLAW_CONFIG}"
    
    log_success "OpenClaw configured to use Ollama at ${OLLAMA_HOST}"
}

start_gateway() {
    log_info "Starting OpenClaw gateway..."
    
    # Check if already running
    if run_cmd "pgrep -f 'openclaw gateway' > /dev/null"; then
        log_warn "Gateway appears to be already running"
        return 0
    fi
    
    # Start gateway in background with --bind lan to listen on all interfaces
    run_cmd "nohup openclaw gateway --bind lan --token ${GATEWAY_TOKEN} > /tmp/openclaw-gateway.log 2>&1 &"
    
    sleep 2
    
    # Check if it started
    if run_cmd "pgrep -f 'openclaw gateway' > /dev/null"; then
        log_success "Gateway started successfully"
        log_info "Web UI: http://${OPENCLAW_LXC}:${GATEWAY_PORT}/#token=${GATEWAY_TOKEN}"
        log_info "Logs: ssh root@${OPENCLAW_LXC} 'tail -f /tmp/openclaw-gateway.log'"
    else
        log_error "Gateway failed to start. Check logs:"
        run_cmd "tail -20 /tmp/openclaw-gateway.log"
        exit 1
    fi
}

stop_gateway() {
    log_info "Stopping OpenClaw gateway..."
    
    if run_cmd "pgrep -f 'openclaw gateway' > /dev/null"; then
        run_cmd "pkill -f 'openclaw gateway'"
        sleep 1
        log_success "Gateway stopped"
    else
        log_warn "Gateway not running"
    fi
}

status_check() {
    log_info "Checking OpenClaw status..."
    
    echo ""
    echo "=== OpenClaw Gateway Status ==="
    if run_cmd "pgrep -f 'openclaw gateway' > /dev/null"; then
        echo -e "${GREEN}Gateway: Running${NC}"
        run_cmd "ps aux | grep 'openclaw gateway' | grep -v grep"
    else
        echo -e "${RED}Gateway: Not running${NC}"
    fi
    
    echo ""
    echo "=== Configuration ==="
    if run_cmd "test -f ${OPENCLAW_CONFIG}"; then
        echo -e "${GREEN}Config: ${OPENCLAW_CONFIG}${NC}"
        run_cmd "jq -r '.models.default // \"not set\"' ${OPENCLAW_CONFIG} 2>/dev/null || echo 'Unable to read config'"
    else
        echo -e "${RED}Config: Not found${NC}"
    fi
    
    echo ""
    echo "=== Ollama Connectivity ==="
    if run_cmd "curl -s http://${OLLAMA_HOST}/api/tags > /dev/null 2>&1"; then
        echo -e "${GREEN}Ollama: Reachable at ${OLLAMA_HOST}${NC}"
        log_info "Available models:"
        run_cmd "curl -s http://${OLLAMA_HOST}/api/tags | jq -r '.models[].name' | head -10"
    else
        echo -e "${RED}Ollama: Not reachable at ${OLLAMA_HOST}${NC}"
    fi
    
    echo ""
    echo "=== Access URLs ==="
    echo "Web UI: http://${OPENCLAW_LXC}:${GATEWAY_PORT}/#token=${GATEWAY_TOKEN}"
    echo "SSH Tunnel: ssh -N -L ${GATEWAY_PORT}:127.0.0.1:${GATEWAY_PORT} root@${OPENCLAW_LXC}"
    echo "Local UI: http://localhost:${GATEWAY_PORT}/#token=${GATEWAY_TOKEN}"
}

test_ollama_model() {
    log_info "Testing Ollama model availability..."
    
    local model="${1:-qwen2.5-coder:3b}"
    
    if run_cmd "curl -s http://${OLLAMA_HOST}/api/tags | jq -e '.models[] | select(.name==\"${model}\")' > /dev/null"; then
        log_success "Model ${model} is available on Ollama"
    else
        log_warn "Model ${model} not found on Ollama. Pulling it now..."
        run_cmd "ollama pull ${model}"
    fi
}

show_usage() {
    cat <<EOF
OpenClaw Setup Script

Usage:
    $0 [COMMAND]

Commands:
    configure       Configure OpenClaw to use local Ollama
    start           Start the OpenClaw gateway
    stop            Stop the OpenClaw gateway
    restart         Restart the gateway
    status          Show current status
    test-model      Test if model is available in Ollama
    full-setup      Run complete setup (configure + start)
    
Examples:
    # Initial setup
    $0 full-setup
    
    # Start gateway
    $0 start
    
    # Check status
    $0 status
    
    # Test model availability
    $0 test-model qwen2.5-coder:14b

Environment Variables:
    OPENCLAW_LXC    LXC IP for OpenClaw (default: ${OPENCLAW_LXC})
    OLLAMA_HOST     Ollama server (default: ${OLLAMA_HOST} - local)
    GATEWAY_PORT    Gateway port (default: ${GATEWAY_PORT})

Notes:
    - LXC 101 is unprivileged - systemd user services unavailable
    - Ollama runs locally on same LXC
    - Gateway runs as background process (nohup)
EOF
}

# Main command dispatcher
case "${1:-status}" in
    configure)
        configure_ollama
        ;;
    start)
        start_gateway
        ;;
    stop)
        stop_gateway
        ;;
    restart)
        stop_gateway
        sleep 1
        start_gateway
        ;;
    status)
        status_check
        ;;
    test-model)
        test_ollama_model "${2:-qwen2.5-coder:14b}"
        ;;
    full-setup)
        configure_ollama
        test_ollama_model "qwen2.5-coder:3b"
        start_gateway
        status_check
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
