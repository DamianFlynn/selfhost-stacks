#!/bin/bash

# Setup script for Teleport stack
# Creates required directory structure on TrueNAS

set -e

APPDATA_BASE="/mnt/fast/appdata/teleport"

echo "Creating Teleport directory structure..."

# Create main directories
mkdir -p "${APPDATA_BASE}"/{data,config,postgres}

# Set ownership to apps:apps (568:568)
chown -R 568:568 "${APPDATA_BASE}"

# Set permissions
chmod -R 755 "${APPDATA_BASE}"

echo "✓ Teleport directory structure created successfully"
echo "  Base: ${APPDATA_BASE}"
echo "  - data/ (Teleport state, certificates, sessions)"
echo "  - config/ (teleport.yaml configuration file)"
echo "  - postgres/ (Audit log and session database)"
echo ""
echo "⚠️  CRITICAL: Distroless image requires manual config file creation!"
echo ""
echo "Create ${APPDATA_BASE}/config/teleport.yaml with:"
echo ""
cat > "${APPDATA_BASE}/config/teleport.yaml" << 'EOF'
version: v3
teleport:
  nodename: teleport
  data_dir: /var/lib/teleport
  auth_token: ${TELEPORT_AUTH_TOKEN}
  
auth_service:
  enabled: yes
  cluster_name: ${CLUSTER_NAME}
  listen_addr: 0.0.0.0:3025
  
proxy_service:
  enabled: yes
  web_listen_addr: 0.0.0.0:3080
  public_addr: ${TELEPORT_PUBLIC_ADDR}:443
  https_keypairs: []
  acme: {}
  
ssh_service:
  enabled: yes
  
db_service:
  enabled: no
EOF

# Replace env vars in config
sed -i "s/\${TELEPORT_AUTH_TOKEN}/$(grep TELEPORT_AUTH_TOKEN /mnt/fast/stacks/teleport/.env | cut -d '=' -f2)/" "${APPDATA_BASE}/config/teleport.yaml"
sed -i "s/\${CLUSTER_NAME}/$(grep CLUSTER_NAME /mnt/fast/stacks/teleport/.env | cut -d '=' -f2)/" "${APPDATA_BASE}/config/teleport.yaml"
sed -i "s/\${TELEPORT_PUBLIC_ADDR}/$(grep TELEPORT_PUBLIC_ADDR /mnt/fast/stacks/teleport/.env | cut -d '=' -f2)/" "${APPDATA_BASE}/config/teleport.yaml"

chown 568:568 "${APPDATA_BASE}/config/teleport.yaml"
chmod 644 "${APPDATA_BASE}/config/teleport.yaml"

echo "✓ Created ${APPDATA_BASE}/config/teleport.yaml"
echo ""
echo "⚠️  IMPORTANT: Teleport needs additional Traefik configuration!"
echo ""
echo "Add these to your Traefik static config (traefik.yaml):"
echo ""
echo "entryPoints:"
echo "  teleport-proxy:"
echo "    address: ':3023'"
echo "  teleport-tunnel:"
echo "    address: ':3024'"
echo ""
echo "Next steps:"
echo "1. Update Traefik config with entrypoints above"
echo "2. Restart Traefik to load new entrypoints"
echo "3. Deploy: docker compose -f /mnt/fast/stacks/wrappers/teleport.app.yaml up -d"
echo "4. Access at: https://access.deercrest.info"
echo "5. Create first admin: docker exec -it teleport tctl users add admin --roles=editor,access --logins=root,ubuntu,administrator"
echo ""
echo "Note: Distroless image has no shell - use 'tctl' commands only, no interactive shell access"
