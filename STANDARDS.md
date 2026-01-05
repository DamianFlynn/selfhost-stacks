# Stack Standardization Documentation

This document describes the standardization applied to all Docker Compose stacks in this repository.

## Standardization Completed

All 18 compose stacks have been reviewed and standardized with consistent formatting and documentation.

## Compose File Structure

All `compose.yaml` files follow this standard format:

```yaml
# Stack Name - Brief description
# Additional context about the stack

name: stack-name

########################### NETWORKS
networks:
  # External networks (e.g., t3_proxy)
  # Internal networks (e.g., service-specific)

########################### SECRETS (if applicable)
secrets:
  # Secret file references

include:
  ########################### SERVICES
  - service1.yaml
  - service2.yaml

########################### VOLUMES (if using named volumes)
volumes:
  volume_name:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/fast/appdata/stack/component
```

## Service File Structure

All service YAML files (e.g., `n8n.yaml`, `radarr.yaml`) follow this header format:

```yaml
# Service Name - Brief Description
#
# Purpose:
#   What this service does and why it exists
#
# Key Features:
#   - Feature 1
#   - Feature 2
#   - Feature 3
#   ...
#
# Workflow:
#   How data/requests flow through the service
#
# Access:
#   URL: https://service.deercrest.info
#   Middleware: chain-authelia (or chain-no-auth)
#

services:
  service-name:
    # Service configuration...
```

## Updated Stacks

### Compose Files with Headers Added
1. ✅ **arrs/compose.yaml** - "Arrs Stack - Media automation suite"
2. ✅ **automation/compose.yaml** - "Automation Stack - n8n, Oxidized, PWPush, Tesla Static"
3. ✅ **code-server/compose.yaml** - "Code Server Stack - VS Code in the browser"
4. ✅ **dawarich/compose.yaml** - Already had proper header
5. ✅ **freshrss/compose.yaml** - "FreshRSS Stack - RSS feed reader and aggregator"
6. ✅ **homarr/compose.yaml** - Already had proper header
7. ✅ **immich/compose.yaml** - "Immich Stack - Photo and video management platform"
8. ✅ **karakeep/compose.yaml** - "Karakeep Stack - Bookmark and content manager"
9. ✅ **keeper-sh/compose.yaml** - "Keeper.sh Stack - Calendar and scheduling service" (also fixed name from "automation")
10. ✅ **media/compose.yaml** - "Media Stack - Jellyfin, Overseerr, Jellystat, Wizarr, Dispatcharr"
11. ✅ **minecraft/compose.yaml** - "Minecraft Stack - Vanilla and Yggdrasil servers"
12. ✅ **open-archiver/compose.yaml** - "Open Archiver Stack - Digital content archiving platform"
13. ✅ **openwebui/compose.yaml** - "Open WebUI Stack - AI chat interface with LLM integration"
14. ✅ **podsync/compose.yaml** - "Podsync Stack - YouTube/Vimeo to podcast converter"
15. ✅ **postiz/compose.yaml** - Already had proper header (newly created)
16. ✅ **teleport/compose.yaml** - Already had proper header (newly created)
17. ✅ **termix/compose.yaml** - Already had proper header (newly created)
18. ✅ **traefik/compose.yaml** - "Traefik Stack - Reverse proxy and load balancer"

### Service Files with Headers Added

#### Automation Stack
- ✅ **n8n.yaml** - Workflow automation platform
- ✅ **oxidized.yaml** - Network device configuration backup
- ✅ **pwpush.yaml** - Password/secret sharing service
- ✅ **tesla-static.yaml** - Tesla Fleet API public key server

#### Minecraft Stack
- ✅ **mc-vanilla.yaml** - Official Minecraft Java Edition server
- ✅ **mc-yggdrasil.yaml** - Modded Minecraft with custom authentication

#### Traefik Stack
- ✅ **traefik.yaml** - Modern HTTP reverse proxy and load balancer
- ✅ **authelia.yaml** - Single sign-on and two-factor authentication
- ✅ **socket-proxy.yaml** - Secure Docker API access
- ✅ **tsproxy.yaml** - Tailscale bridge for Docker services

### Service Files Already Standardized

These stacks already had proper headers following the dispatcharr.yaml pattern:

#### Arrs Stack
- ✅ **radarr.yaml** - Movie collection manager
- ✅ **sonarr.yaml** - TV show collection manager
- ✅ **lidarr.yaml** - Music collection manager
- ✅ **prowlarr.yaml** - Indexer manager and proxy
- ✅ **qbittorrent.yaml** - BitTorrent client
- ✅ **sabnzbd.yaml** - Usenet downloader
- ✅ **bazarr.yaml** - Subtitle downloader

#### Media Stack
- ✅ **jellyfin.yaml** - Media server
- ✅ **seerr.yaml** - Media request management
- ✅ **dispatcharr.yaml** - Live TV proxy and DVR processor (original template)
- ✅ **jellystat.yaml** - Jellyfin statistics
- ✅ **wizarr.yaml** - User invitation system

## Standard Patterns

### Network Configuration
- **External Network**: `t3_proxy` - Used by Traefik for reverse proxy access
- **Internal Networks**: Created per-stack for service-to-service communication
  - Examples: `postiz`, `teleport`, `dawarich`, `pwpush`, etc.

### Volume Mounting
- **Base Path**: `/mnt/fast/appdata/{stack}/{component}`
- **User/Group**: 568:568 (apps:apps on TrueNAS SCALE)
- **Permissions**: 755 for directories, 644 for files

### Environment Files
All stacks use `.env` files with this structure:
```bash
# Stack Name Configuration
# Brief description

# Required Settings
SETTING_NAME=value

# Generated Secrets
SECRET_KEY=generated_value

# Optional Settings (commented by default)
# OPTIONAL_SETTING=value
```

### Traefik Integration
Services use these standard middleware chains:
- `chain-authelia@file` - Protected services requiring authentication
- `chain-no-auth@file` - Public services or services with built-in auth

### TrueNAS Integration
All stacks include a wrapper file in `wrappers/*.app.yaml`:
```yaml
# Stack Name - TrueNAS SCALE Wrapper
# Includes the actual stack from /mnt/fast/stacks

services: {}

include:
  - /mnt/fast/stacks/{stack}/compose.yaml
```

## Benefits of Standardization

1. **Consistency** - All stacks follow the same structure and documentation pattern
2. **Maintainability** - Easy to understand and modify any stack
3. **Documentation** - Each service has clear purpose, features, and workflow descriptions
4. **Onboarding** - New team members can quickly understand the infrastructure
5. **Troubleshooting** - Consistent patterns make debugging easier
6. **Scalability** - Easy to add new stacks following established patterns

## Future Maintenance

When adding new stacks:
1. Create `compose.yaml` with header, name, networks, include, and volumes
2. Create service YAML files with full header (Purpose/Features/Workflow/Access)
3. Create `.env` file with header and organized sections
4. Create setup script in `scripts/setup-{stack}.sh`
5. Create TrueNAS wrapper in `wrappers/{stack}.app.yaml`
6. Follow existing patterns for Traefik labels and network configuration
