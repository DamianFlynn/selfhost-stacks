# Container Backlog

Services and applications to evaluate for future deployment.

---

## ✅ Implemented

### Immich Kiosk
- **Repository**: https://github.com/damongolding/immich-kiosk
- **Purpose**: Kiosk mode display for Immich photo library
- **Stack**: `immich`
- **Status**: ✅ Added to immich/compose.yaml
- **Access**: https://kiosk.deercrest.info
- **Notes**: Integrates with existing Immich deployment for slideshow displays

### Audiobookshelf
- **Repository**: https://github.com/advplyr/audiobookshelf
- **Purpose**: Audiobook and podcast server
- **Stack**: `media`
- **Status**: ✅ Added to media/audiobookshelf.yaml
- **Access**: https://audiobooks.deercrest.info
- **Notes**: Self-hosted audiobook and podcast library with mobile apps

### Listenarr
- **Repository**: https://github.com/Listenarrs/Listenarr
- **Purpose**: Audiobook automation for *arr stack
- **Stack**: `arrs`
- **Status**: ✅ Added to arrs/listenarr.yaml
- **Access**: https://listenarr.deercrest.info
- **Notes**: Integrates with Prowlarr, SABnzbd, and qBittorrent workflow

### ROMM
- **Repository**: https://github.com/rommapp/romm
- **Purpose**: ROM library management for retro gaming
- **Stack**: `gaming` (new)
- **Status**: ✅ Created gaming/romm.yaml
- **Access**: https://roms.deercrest.info
- **Database**: MariaDB 11 + Redis
- **Notes**: Beautiful ROM collection manager with IGDB metadata integration

### Rybbit
- **Repository**: https://github.com/rybbit-io/rybbit
- **Purpose**: Self-hosted Reddit client and content curator
- **Stack**: `social` (new)
- **Status**: ✅ Created social/rybbit.yaml
- **Access**: https://rybbit.deercrest.info
- **Database**: PostgreSQL 17
- **Notes**: Integrates with Postiz for social posting and Hugo static site

### Paperless-ngx (Full Stack)
- **Repository**: https://github.com/paperless-ngx/paperless-ngx
- **Purpose**: Document management with OCR and full-text search
- **Stack**: `documents` (new)
- **Status**: ✅ Created documents/paperless.yaml
- **Access**: https://docs.deercrest.info
- **Database**: PostgreSQL 17 + Redis
- **Components**: Paperless + Tika OCR + Gotenberg PDF + Paperless-GPT
- **Notes**: Complete DMS with AI-powered tagging via Paperless-GPT

### Paperless-GPT
- **Repository**: https://github.com/icereed/paperless-gpt
- **Purpose**: AI-powered document classification for Paperless
- **Stack**: `documents`
- **Status**: ✅ Created documents/paperless-gpt.yaml
- **Access**: https://docs-ai.deercrest.info
- **Notes**: Automatic tagging, correspondent detection, and document type classification

### Booklore
- **Repository**: https://github.com/booklore-app/booklore
- **Purpose**: Book tracking and library management
- **Stack**: `books` (new)
- **Status**: ✅ Created books/booklore.yaml
- **Access**: https://books.deercrest.info
- **Database**: PostgreSQL 17
- **Notes**: Personal book collection tracker with reading progress

### Cal.com
- **Repository**: https://github.com/calcom/cal.com
- **Purpose**: Resource booking and scheduling platform
- **Stack**: `saas` (new)
- **Status**: ✅ Created saas/calcom.yaml
- **Access**: https://cal.deercrest.info
- **Database**: PostgreSQL 17
- **Notes**: Self-hosted Calendly alternative for SaaS booking business

---

## 📦 New Stacks Created

- **social**: Postiz (social media scheduling) + Rybbit (Reddit client)
- **documents**: Paperless-ngx + Paperless-GPT + Tika + Gotenberg
- **books**: Booklore (book tracking)
- **gaming**: ROMM (ROM library management)
- **saas**: Cal.com (booking and scheduling platform)

---

## 🔜 To Categorize and Implement

### *arr Stack Extensions

#### Swiparr
- **Repository**: https://github.com/m3sserstudi0s/swiparr
- **Purpose**: Tinder-style swipe interface for media selection
- **Stack**: `arrs` (recommended)
- **Status**: 🔜 To implement
- **Notes**: Gamified discovery - swipe right for movies/shows you want to watch

#### Trailarr
- **Repository**: https://github.com/nandyalu/trailarr
- **Purpose**: Automatic trailer downloader for Radarr/Sonarr
- **Stack**: `arrs` (recommended)
- **Status**: 🔜 To implement
- **Notes**: Downloads and organizes trailers for your media library

#### Scraparr
- **Repository**: https://github.com/thecfu/scraparr
- **Purpose**: Web scraping and extras management for *arr
- **Stack**: `arrs` (recommended)
- **Status**: 🔜 To implement
- **Notes**: Automated extras, behind-the-scenes content fetching

#### Codebarr
- **Repository**: https://github.com/adelatour11/codebarr
- **Purpose**: Software/code library management (*arr variant)
- **Stack**: `arrs` OR new `dev` stack
- **Status**: 🔜 To evaluate
- **Notes**: Could warrant separate development tools stack

#### MCP-Arr
- **Repository**: https://github.com/aplaceforallmystuff/mcp-arr
- **Purpose**: Model Context Protocol server for *arr applications
- **Stack**: `arrs` OR `automation`
- **Status**: 🔜 To evaluate
- **Notes**: AI integration for arr stack via MCP

#### Boxarr
- **Repository**: https://github.com/iongpt/boxarr
- **Purpose**: Box set and collection management
- **Stack**: `arrs`
- **Status**: ⚠️ Commented in arrs/compose.yaml (requires source build)
- **Notes**: Already in repo, waiting for Docker Hub image

#### Blockbusterr
- **Repository**: https://github.com/Mahcks/blockbusterr
- **Purpose**: Randomized movie night selector
- **Stack**: `arrs`
- **Status**: ✅ Already deployed in arrs/blockbusterr.yaml
- **Notes**: Active and operational

### Media Stack Extensions

#### Tunarr
- **Repository**: https://tunarr.com / https://github.com/chrisbenincasa/tunarr
- **Purpose**: Create live TV channels from your media library
- **Stack**: `media` (recommended)
- **Status**: 🔜 To implement
- **Notes**: Turn movies/shows into 24/7 streaming channels like Plex Live TV

#### Karaoke for Jellyfin
- **Repository**: https://github.com/johnpc/karaoke-for-jellyfin
- **Purpose**: Karaoke plugin/extension for Jellyfin
- **Stack**: `media` (recommended)
- **Status**: 🔜 To implement
- **Notes**: Adds karaoke functionality to Jellyfin media server

### Security & Productivity

#### Bitwarden MCP Server
- **Repository**: https://github.com/bitwarden/mcp-server
- **Purpose**: MCP server for Bitwarden password manager
- **Stack**: New `security` OR `automation`
- **Status**: 🔜 To evaluate
- **Notes**: AI agents integration with password management

#### AutoResume
- **Repository**: https://github.com/aadya940/autoresume
- **Purpose**: AI-powered resume builder and optimization
- **Stack**: New `career` OR `automation`
- **Status**: 🔜 To evaluate
- **Notes**: Could be useful for professional portfolio management

#### Atlas
- **Repository**: https://github.com/karam-ajaj/atlas
- **Purpose**: [Need to verify - could be mapping, project management, or knowledge base]
- **Stack**: 🔍 To research
- **Status**: 🔜 To evaluate
- **Notes**: Requires investigation to determine purpose and fit

---

## 📊 Stack Mapping Summary

**arrs** (Media Automation):
- ✅ Active: blockbusterr, listenarr, radarr, sonarr, lidarr, readarr, bazarr, prowlarr
- ⚠️ Buildable: boxarr (requires source build)
- 🔜 To add: swiparr, trailarr, scraparr, codebarr(?), mcp-arr(?)

**media** (Media Servers):
- ✅ Active: jellyfin, audiobookshelf, seerr, jellystat, wizarr, dispatcharr
- 🔜 To add: tunarr, karaoke-for-jellyfin

**New Stacks to Consider**:
- `security`: Bitwarden MCP, password management, vault services
- `career`: AutoResume, professional tools, portfolio management
- `dev`: Codebarr(?), development tools and library management

---

## Evaluation Criteria

When evaluating new containers, consider:

- [ ] Docker image availability and quality
- [ ] Resource requirements (CPU, RAM, storage)
- [ ] Integration with existing services
- [ ] Maintenance and update frequency
- [ ] Community support and documentation
- [ ] Security considerations
- [ ] Traefik routing requirements
- [ ] Backup and data persistence needs
