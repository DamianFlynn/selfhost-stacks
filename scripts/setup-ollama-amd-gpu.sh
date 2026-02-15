#!/bin/bash
#
# setup-ollama-amd-gpu.sh — Configure Ollama with AMD GPU acceleration (Vulkan)
#
# This script:
#   1. Ensures render/video groups have correct GIDs (110/44)
#   2. Installs Vulkan drivers and Mesa for AMD Radeon 890M (Strix/RDNA 3.5)
#   3. Configures Ollama systemd service for Vulkan GPU acceleration
#   4. Tests GPU detection and availability
#
# Supports: AMD Radeon 890M (RDNA 3.5/Strix) via Mesa RADV Vulkan drivers
#
# Usage:
#   Run this script inside the openclaw LXC container as root:
#     bash setup-ollama-amd-gpu.sh
#
#   Or from Proxmox host:
#     pct exec <vmid> -- bash -c "$(cat setup-ollama-amd-gpu.sh)"
#
# Note: This script assumes GPU device passthrough is already configured
#       in the LXC config (/etc/pve/lxc/<vmid>.conf)
#

set -e

echo "=== Ollama AMD GPU Setup for Radeon 890M (Strix/RDNA 3.5) ==="
echo ""
echo "Strategy: Vulkan GPU acceleration via Mesa RADV drivers"
echo ""

# ── Step 1: Fix render/video groups ─────────────────────────────────────────
echo "[1/5] Ensuring render and video groups have correct GIDs..."

# Ensure video group exists with GID 44
getent group video >/dev/null 2>&1 || groupadd -g 44 video

# Ensure render group exists with GID 110 (NOT dynamic GID like 992)
getent group render >/dev/null 2>&1 || groupadd -g 110 render

# Force render group to GID 110 if it exists with wrong GID
current_render_gid=$(getent group render | cut -d: -f3)
if [ "$current_render_gid" != "110" ]; then
    echo "  ⚠ Render group has wrong GID ($current_render_gid), fixing to 110..."
    groupmod -g 110 render
    echo "  ✓ Render group changed from GID $current_render_gid → 110"
    echo "  ⚠ Container restart required for device ownership to update"
fi

echo "  Current groups:"
getent group video render
echo ""

# ── Step 2: Add ollama user to GPU groups ───────────────────────────────────
echo "[2/5] Adding ollama user to video and render groups..."

if id ollama &>/dev/null; then
    usermod -aG video ollama
    usermod -aG render ollama
    echo "  ✓ ollama user added to video and render groups"
    id ollama
else
    echo "  ⚠ WARNING: ollama user not found — Ollama may not be installed yet"
fi
echo ""

# ── Step 3: Install Vulkan drivers ──────────────────────────────────────────
echo "[3/5] Installing Vulkan drivers and Mesa for AMD GPU..."
echo "  Note: This may take a minute..."

apt-get update -qq

# Install Vulkan tools and Mesa RADV drivers
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    vulkan-tools \
    mesa-vulkan-drivers \
    mesa-utils \
    vainfo \
    libva-dev \
    libdrm-amdgpu1

echo "  ✓ Vulkan drivers installed"
echo ""

# ── Step 4: Configure Ollama for Vulkan GPU ─────────────────────────────────
echo "[4/5] Configuring Ollama for Vulkan GPU acceleration..."

# Create systemd override directory
mkdir -p /etc/systemd/system/ollama.service.d/

# Create Ollama GPU configuration
cat > /etc/systemd/system/ollama.service.d/amd-gpu.conf <<'EOF'
[Service]
# AMD GPU configuration for Radeon 890M (RDNA 3.5/Strix)
Environment="HSA_OVERRIDE_GFX_VERSION=11.0.3"
Environment="OLLAMA_DEBUG=1"
Environment="OLLAMA_VULKAN=1"

# Run as ollama user with GPU group access
User=ollama
SupplementaryGroups=video render

# Ensure GPU devices are accessible
DeviceAllow=/dev/dri/card1 rw
DeviceAllow=/dev/dri/renderD128 rw
EOF

# Reload and restart Ollama
systemctl daemon-reload
systemctl restart ollama

echo "  ✓ Ollama configured for Vulkan GPU (HSA_OVERRIDE_GFX_VERSION=11.0.3)"
echo "  ✓ Ollama service restarted"
echo ""

# ── Step 5: Test GPU detection ──────────────────────────────────────────────
echo "[5/5] Testing GPU detection..."

# Check GPU device permissions
echo "  /dev/dri devices:"
ls -la /dev/dri/ 2>/dev/null || echo "  ⚠ /dev/dri not found"
echo ""

# Check Vulkan devices as ollama user
echo "  Vulkan devices (as ollama user):"
su - ollama -s /bin/bash -c "vulkaninfo 2>&1 | grep -i 'deviceName\|driverInfo' | head -10" || echo "  ⚠ Vulkan check failed"
echo ""

# Check Ollama status
echo "  Ollama service status:"
systemctl status ollama --no-pager | head -15
echo ""

# Wait for Ollama to be ready
sleep 3

echo "=== Setup Complete ==="
echo ""
echo "Expected GPU detection in logs:"
echo "  • deviceName: AMD Radeon Graphics (RADV GFX1150)"
echo "  • offloaded 29/29 layers to GPU"
echo "  • Vulkan0 model buffer size = ~1900 MiB"
echo ""
echo "Next steps:"
echo "  1. Pull a model:    ollama pull qwen2.5-coder:3b    # Recommended for coding"
echo "                      ollama pull llama3.2            # General purpose"
echo "  2. Run a model:     ollama run qwen2.5-coder:3b"
echo "  3. Check GPU logs:  journalctl -u ollama -n 50 | grep -i 'vulkan\|gpu'"
echo "  4. Monitor GPU:     watch -n 0.5 'cat /sys/class/drm/card1/device/gpu_busy_percent'"
echo ""
echo "Performance expectations:"
echo "  • qwen2.5-coder:3b: ~7-10 seconds for 100-word response (RECOMMENDED)"
echo "  • llama3.2:3b: ~7-10 seconds for 100-word response"
echo "  • GPU usage should spike to 70-98% during inference"
echo "  • Cold start (first run) is slower due to model loading"
echo ""
echo "Troubleshooting:"
echo "  • If render group was changed, restart LXC: pct restart <vmid>"
echo "  • Check logs: journalctl -u ollama -f"
echo "  • Verify GPU: su - ollama -s /bin/bash -c 'vulkaninfo | grep deviceName'"
echo ""
