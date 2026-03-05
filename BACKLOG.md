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
