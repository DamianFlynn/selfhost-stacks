# Deployment Guide for TrueNAS Scale Traefik Stack

## Overview
This guide will help you deploy a complete Traefik reverse proxy stack on your new TrueNAS Scale server (Minisforum N5Pro) and expose your Immich instance securely.

## Prerequisites

### 1. Domain and Cloudflare Setup
- Have a domain registered and pointed to Cloudflare
- Get your Cloudflare Zone ID from the dashboard
- Create a Cloudflare API token with permissions:
  - Zone: Zone Settings:Read
  - Zone: Zone:Read  
  - Zone: DNS:Edit

### 2. TrueNAS Scale Directory Structure
On your TrueNAS Scale server, create the required directory structure:

```bash
# Create the main stack directories
sudo mkdir -p /mnt/fast/stacks/{core,immich}
sudo mkdir -p /mnt/fast/appdata/{traefik3,authelia,shared/certs,secrets/core,immich}

# Create traefik subdirectories
sudo mkdir -p /mnt/fast/appdata/traefik3/{rules,acme,logs}

# Create media directories (adjust paths as needed)
sudo mkdir -p /mnt/tank/media/photos

# Set ownership to apps user (adjust UID/GID as needed)
sudo chown -R 568:568 /mnt/fast/stacks /mnt/fast/appdata
sudo chmod -R 775 /mnt/fast/stacks /mnt/fast/appdata

# Secure the acme.json file
sudo touch /mnt/fast/appdata/traefik3/acme/acme.json
sudo chmod 600 /mnt/fast/appdata/traefik3/acme/acme.json
sudo chown 568:568 /mnt/fast/appdata/traefik3/acme/acme.json
```

## Deployment Steps

### Step 1: Copy Files to TrueNAS
Copy the stack files to your TrueNAS Scale server:

```bash
# Copy the core stack
scp -r core/* your-truenas-ip:/mnt/fast/stacks/core/

# Copy the immich stack  
scp -r immich/* your-truenas-ip:/mnt/fast/stacks/immich/

# Copy the middleware rules
scp traefik-rules/*.yml your-truenas-ip:/mnt/fast/appdata/traefik3/rules/
```

### Step 2: Configure Environment Files
On your TrueNAS Scale server:

```bash
# Configure core stack environment
cd /mnt/fast/stacks/core
cp .env.sample .env
nano .env  # Edit with your domain and settings

# Configure Immich environment
cd /mnt/fast/stacks/immich  
cp .env.sample .env
nano .env  # Edit with your paths and database credentials
```

### Step 3: Create Secrets
Create the required secret files:

```bash
# Cloudflare API credentials
echo "your-email@domain.com" | sudo tee /mnt/fast/appdata/traefik/secrets/cf_email
echo "your-cloudflare-api-token" | sudo tee /mnt/fast/appdata/traefik/secrets/cf_api_token
echo "your-cloudflare-dns-api-token" | sudo tee /mnt/fast/appdata/traefik/secrets/cf_dns_api_token
echo "your-cloudflare-zone-id" | sudo tee /mnt/fast/appdata/traefik/secrets/cf_zone_id

# Generate Authelia secrets
openssl rand -base64 32 | sudo tee /mnt/fast/appdata/traefik/secrets/authelia_jwt_secret
openssl rand -base64 32 | sudo tee /mnt/fast/appdata/traefik/secrets/authelia_session_secret  
openssl rand -base64 32 | sudo tee /mnt/fast/appdata/traefik/secrets/authelia_storage_encryption_key

# Optional basic auth
echo "admin:$(openssl passwd -apr1 your-password)" | sudo tee /mnt/fast/appdata/traefik/secrets/basic_auth_credentials

# Set correct permissions
sudo chown -R 568:568 /mnt/fast/appdata/secrets
sudo chmod -R 600 /mnt/fast/appdata/traefik/secrets/*
```

### Step 4: Deploy via TrueNAS Apps

#### Deploy Core Stack (Traefik + Authelia)
1. Go to **Apps > Discover Apps > Install via YAML**
2. Copy and paste the contents of `wrappers/core.app.yaml`:
   ```yaml
   services: {}
   include:
     - /mnt/fast/stacks/core/compose.yaml
   ```
3. Click **Save** and name it "traefik-core"

#### Deploy Immich Stack
1. Wait for the core stack to be fully running
2. Go to **Apps > Discover Apps > Install via YAML**
3. Copy and paste the contents of `wrappers/immich.app.yaml`:
   ```yaml
   services: {}
   include:
     - /mnt/fast/stacks/immich/compose.yaml
   ```
4. Click **Save** and name it "immich"

### Step 5: Configure Authelia (Optional)
If you want to protect certain services with authentication:

1. SSH into your TrueNAS Scale server
2. Edit the Authelia configuration:
   ```bash
   sudo mkdir -p /mnt/fast/appdata/authelia
   # Copy a basic Authelia configuration file
   ```

## Access Your Services

After deployment, you should be able to access:

- **Traefik Dashboard**: `https://traefik.your-domain.com`
- **Authelia**: `https://authelia.your-domain.com`  
- **Immich**: `https://photos.your-domain.com`

## Troubleshooting

### Check Container Status
```bash
docker ps
docker logs traefik
docker logs authelia
docker logs immich_server
```

### Network Issues
```bash
docker network ls
docker network inspect t3_proxy
```

### Certificate Issues
```bash
cat /mnt/fast/appdata/traefik3/acme/acme.json
```

### DNS Issues
- Verify your Cloudflare API tokens are correct
- Check the Cloudflare companion logs: `docker logs cf-companion`

## Security Notes

1. **Firewall**: Only expose ports 80 and 443 on your firewall
2. **Authelia**: Configure 2FA for additional security
3. **Updates**: Keep your containers updated via Renovate or manually
4. **Backups**: Backup your `/mnt/fast/appdata` directory regularly

## Adding More Services

To add more services behind Traefik, use these labels in your compose files:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp-rtr.entrypoints=websecure"
  - "traefik.http.routers.myapp-rtr.rule=Host(`myapp.${DOMAINNAME}`)"
  - "traefik.http.routers.myapp-rtr.tls=true"
  - "traefik.http.routers.myapp-rtr.tls.certresolver=dns-cloudflare"
  - "traefik.http.routers.myapp-rtr.middlewares=chain-no-auth@file"  # or chain-authelia@file
  - "traefik.http.routers.myapp-rtr.service=myapp-svc"
  - "traefik.http.services.myapp-svc.loadbalancer.server.port=PORT"
```

Make sure to add your services to the `t3_proxy` network!