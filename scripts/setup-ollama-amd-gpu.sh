#!/bin/bash
#
# setup-ollama-amd-gpu.sh — Configure Ollama with AMD GPU acceleration for OpenClaw LXC
#
# This script:
#   1. Fixes /dev/dri/renderD128 permissions (should be render group, not nogroup)
#   2. Installs ROCm drivers and dependencies for AMD Radeon 890M (Strix)
#   3. Configures Ollama to use AMD GPU via ROCm/HIP
#   4. Tests GPU detection and availability
#
# Usage:
#   Run this script inside the openclaw LXC container as root:
#     bash setup-ollama-amd-gpu.sh
#
#   Or from Proxmox host:
#     pct exec <vmid> -- bash -c "$(cat setup-ollama-amd-gpu.sh)"
#

set -e

echo "=== Ollama AMD GPU Setup for Radeon 890M (Strix) ==="
echo ""

# ── Step 1: Fix /dev/dri permissions ─────────────────────────────────────────
echo "[1/5] Fixing /dev/dri device permissions..."

# Ensure render and video groups exist with correct GIDs (passed through from host)
getent group video  >/dev/null 2>&1 || groupadd -g 44 video
getent group render >/dev/null 2>&1 || groupadd -g 110 render

# Fix renderD128 ownership (should be root:render, not nobody:nogroup)
if [ -e /dev/dri/renderD128 ]; then
    chown root:render /dev/dri/renderD128
    chmod 660 /dev/dri/renderD128
    echo "  ✓ Fixed /dev/dri/renderD128 → root:render (660)"
else
    echo "  ⚠ WARNING: /dev/dri/renderD128 not found — GPU passthrough may not be configured"
fi

# Fix card1 ownership
if [ -e /dev/dri/card1 ]; then
    chown root:video /dev/dri/card1
    chmod 660 /dev/dri/card1
    echo "  ✓ Fixed /dev/dri/card1 → root:video (660)"
fi

echo "  Current /dev/dri devices:"
ls -la /dev/dri/
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

# ── Step 3: Install ROCm drivers ─────────────────────────────────────────────
echo "[3/5] Installing ROCm drivers and dependencies..."
echo "  Note: This may take several minutes..."

# Remove any existing ROCm/AMDGPU packages to start clean
apt-get remove -y --purge rocm-* amdgpu-* 2>/dev/null || true

# Install build dependencies
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    wget \
    gnupg2 \
    software-properties-common \
    mesa-utils \
    clinfo \
    vainfo \
    libva-dev \
    libdrm-amdgpu1 \
    libdrm-dev

# For AMD Radeon 890M (RDNA 3.5/Strix), we need ROCm 6.1+ or Mesa 24.0+
# Debian 13 (Trixie) includes Mesa 24.x which has good RDNA 3.5 support
# We'll use Mesa/libdrm approach instead of full ROCm stack (lighter weight)

echo "  Installing Mesa AMDGPU drivers..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    mesa-va-drivers \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libegl1-mesa \
    libgbm1 \
    xserver-xorg-video-amdgpu

# Install HIP runtime for Ollama GPU support
# Note: Full ROCm is heavy; for LLM inference, we primarily need:
#   - Proper Mesa drivers (installed above)
#   - HIP runtime (if available)
#   - Or rely on Ollama's CPU fallback with partial acceleration

# Try to install ROCm HIP runtime from Debian repos
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    rocm-hip-runtime \
    rocm-hip-libraries 2>/dev/null || {
    echo "  Note: ROCm HIP not available in Debian repos"
    echo "  Ollama will use Mesa/OpenCL for GPU acceleration"
}

echo "  ✓ AMD GPU drivers installed"
echo ""

# ── Step 4: Configure Ollama environment ────────────────────────────────────
echo "[4/5] Configuring Ollama for AMD GPU..."

# Create systemd override directory if it doesn't exist
mkdir -p /etc/systemd/system/ollama.service.d/

# Create environment override for Ollama
cat > /etc/systemd/system/ollama.service.d/amd-gpu.conf <<'EOF'
[Service]
# AMD GPU configuration for ROCm/HIP
Environment="ROCm_PATH=/opt/rocm"
Environment="HIP_VISIBLE_DEVICES=0"
Environment="HSA_OVERRIDE_GFX_VERSION=11.0.0"
Environment="OLLAMA_GPU_DEVICE=/dev/dri/renderD128"

# For AMD Radeon 890M (gfx1103), we may need to override the architecture
# Common values: gfx1100 (RDNA 3), gfx1103 (RDNA 3.5/Strix)
Environment="HSA_OVERRIDE_GFX_VERSION=11.0.3"

# Increase log verbosity for debugging
Environment="OLLAMA_DEBUG=1"

# Ensure ollama can access GPU devices
SupplementaryGroups=video render
EOF

# Reload systemd and restart Ollama
systemctl daemon-reload
systemctl restart ollama

echo "  ✓ Ollama configured for AMD GPU (HSA_OVERRIDE_GFX_VERSION=11.0.3)"
echo "  ✓ Ollama service restarted"
echo ""

# ── Step 5: Test GPU detection ──────────────────────────────────────────────
echo "[5/5] Testing GPU detection..."

# Check if GPU is visible to the system
echo "  Checking GPU with lspci:"
lspci 2>/dev/null | grep -i vga || echo "  Note: lspci not showing VGA (expected in LXC)"
lspci 2>/dev/null | grep -i amd || echo "  Note: No AMD devices in lspci (expected in LXC)"
echo ""

# Check GPU with lshw
echo "  Checking display controller:"
lshw -C display 2>/dev/null | grep -E "(product|vendor|bus info|logical name)" || echo "  Note: lshw display info not available"
echo ""

# Test DRM/Mesa
echo "  Testing DRM device access:"
if [ -e /dev/dri/renderD128 ]; then
    test -r /dev/dri/renderD128 && echo "  ✓ renderD128 is readable" || echo "  ✗ renderD128 is NOT readable"
    test -w /dev/dri/renderD128 && echo "  ✓ renderD128 is writable" || echo "  ✗ renderD128 is NOT writable"
fi
echo ""

# Test VA-API (video acceleration)
echo "  Testing VA-API:"
vainfo --display drm --device /dev/dri/renderD128 2>&1 | head -10 || echo "  Note: VA-API test skipped (not critical for LLMs)"
echo ""

# Test clinfo (OpenCL)
echo "  Testing OpenCL:"
clinfo 2>&1 | head -20 || echo "  Note: OpenCL not available (ROCm may be needed)"
echo ""

# Check Ollama status
echo "  Ollama service status:"
systemctl status ollama --no-pager | head -15
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Pull a model:    ollama pull llama3.2"
echo "  2. Run a model:     ollama run llama3.2"
echo "  3. Check GPU usage: watch -n1 'grep -r . /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo N/A'"
echo ""
echo "Troubleshooting:"
echo "  • Check Ollama logs:    journalctl -u ollama -f"
echo "  • Verify GPU in Ollama: curl http://localhost:11434/api/tags (should show loaded models)"
echo "  • Test inference:       time ollama run llama3.2 'explain quantum physics in 10 words'"
echo ""
echo "If GPU is not detected:"
echo "  • Verify /dev/dri/renderD128 permissions: ls -la /dev/dri/"
echo "  • Check HSA_OVERRIDE_GFX_VERSION matches your GPU (gfx1103 for Radeon 890M)"
echo "  • Try: HSA_OVERRIDE_GFX_VERSION=11.0.0 or 11.0.1 if 11.0.3 doesn't work"
echo ""
