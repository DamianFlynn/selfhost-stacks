# Renovate Review - 2026-06-11

## Summary

**11 Pending PRs** from Renovate - categorized by risk level and required actions.

## 🚨 HIGH RISK - Requires Migration Planning

### 1. PostgreSQL 17 → 18 (MAJOR VERSION)
**Branch:** `origin/renovate/docker.io-postgres-18.x`  
**Impact:** 16 PostgreSQL instances across multiple stacks  
**Status:** ⛔ **BLOCKED - Requires pg_dump/restore or pg_upgrade**

**Affected Stacks:**
- `keeper-sh` - postgres:17 → postgres:18
- `open-archiver` - postgres:17-alpine → postgres:18-alpine
- `automation/n8n` - postgres:16-alpine → postgres:18-alpine
- `automation/pwpush` - postgres:16 → postgres:18
- `books/booklore` - postgres:17-alpine → postgres:18-alpine
- `documents/paperless` - postgres:17-alpine → postgres:18-alpine
- `mattermost` - postgres:16-alpine → postgres:18-alpine
- `media/jellystat` - postgres:15.17 → postgres:18
- `postiz` - postgres:17-alpine → postgres:18-alpine
- `saas/calcom` - postgres:17-alpine → postgres:18-alpine
- `social/postiz` - postgres:17-alpine → postgres:18-alpine
- `social/rybbit` - postgres:17-alpine → postgres:18-alpine
- `teleport` - postgres:17-alpine → postgres:18-alpine
- ✅ `immich` - PINNED at postgres:14 (ghcr.io/immich-app/postgres with vectorchord)

**Migration Steps Required:**
1. Backup each database: `docker exec <container> pg_dump -U <user> <db> > backup.sql`
2. Test restore on postgres:18 container first
3. Document any breaking changes in PostgreSQL 18
4. Plan downtime window per stack
5. Update one stack at a time with validation

**Renovate Rule Needed:**
```json
{
  "description": "PostgreSQL major versions require manual migration",
  "matchDatasources": ["docker"],
  "matchPackageNames": ["postgres", "docker.io/postgres"],
  "matchUpdateTypes": ["major"],
  "enabled": false,
  "addLabels": ["postgres", "major-migration-required", "manual-only"]
}
```

---

## ⚠️ MEDIUM RISK - Review Before Merge

### 2. Grafana Monorepo v12.4.4
**Branch:** `origin/renovate/grafana-monorepo`  
**Type:** Minor update  
**Action:** Review changelog, test dashboards after update  

### 3. Minecraft Bedrock v2026.5.4
**Branch:** `origin/renovate/itzg-minecraft-bedrock-server-2026.x`  
**Type:** Patch update  
**Action:** Check world compatibility, test with kids before committing  

---

## ✅ LOW RISK - Safe to Merge

### 4. Apache Tika v3.3.1.0
**Branch:** `origin/renovate/apache-tika-3.x`  
**Type:** Patch (3.3.0 → 3.3.1)  
**Action:** ✅ Auto-merge (documents stack)

### 5. Authelia v4.39.20
**Branch:** `origin/renovate/authelia-authelia-4.x`  
**Type:** Patch update (security-critical component)  
**Action:** ✅ Merge after quick auth test

### 6. PwPush v2.7.2
**Branch:** `origin/renovate/docker.io-pglombardo-pwpush-2.x`  
**Type:** Minor update  
**Action:** ✅ Auto-merge (automation stack)

### 7. Dawarich v1.8.0
**Branch:** `origin/renovate/freikin-dawarich-1.x`  
**Type:** Minor update  
**Action:** ✅ Merge (location tracking - check GPS integration still works)

### 8. Meilisearch v1.x
**Branch:** `origin/renovate/getmeili-meilisearch-1.x`  
**Type:** Minor update  
**Action:** ✅ Auto-merge (search engine)

### 9. Nginx v1.31.1
**Branch:** `origin/renovate/nginx-1.x`  
**Type:** Patch update  
**Action:** ✅ Auto-merge

### 10. Ollama v0.30.7
**Branch:** `origin/renovate/ollama-ollama-0.x`  
**Type:** Patch update  
**Action:** ✅ Merge (check model compatibility)

### 11. Traefik v3.7.5
**Branch:** `origin/renovate/traefik-3.x`  
**Type:** Patch (3.7.4 → 3.7.5)  
**Action:** ✅ Merge (edge proxy - test routing after update)

---

## Renovate Configuration Issues Found

### 1. ⚠️ PostgreSQL Not Properly Gated
**Current:** Only Immich Postgres pinned  
**Problem:** All other Postgres instances can major-version upgrade  
**Fix:** Add global rule to disable major Postgres updates

### 2. ✅ Pattern Coverage Looks Good
**Pattern:** `/stacks/selfhosted/.*\\.ya?ml$/`  
**Coverage:** 112 YAML files tracked (28 compose.yaml + 84 service files)

### 3. ⚠️ Missing Stack Labels
**Missing labels for:**
- `keeper-sh` (calendar sync)
- `rustdesk` (remote desktop)
- `open-archiver` (archive service)
- `dawarich` (location tracking)
- `books` (booklore)
- `social` stack
- `saas` stack

---

## Recommended Actions

### Immediate (Today)
1. ✅ Add PostgreSQL major-version blocking rule to renovate.json
2. ✅ Add missing stack labels to renovate.json
3. ✅ Merge safe updates (tika, nginx, meilisearch, pwpush)
4. ⚠️ Test Authelia v4.39.20 (security component)
5. ⚠️ Test Traefik v3.7.5 (edge proxy)

### Short Term (This Week)
1. 📝 Document PostgreSQL migration procedure
2. 📋 Create pg_dump backup script for all Postgres stacks
3. 🧪 Test Postgres 18 migration on non-critical stack (pwpush or booklore)
4. ✅ Merge Grafana, Ollama, Dawarich after testing

### Long Term (This Month)
1. 🔄 Migrate all Postgres instances to v18 (one stack at a time)
2. 📊 Create health check script (scripts/check-server-health.sh enhancement)
3. 🤖 Set up automated backup validation

---

## Breaking Changes to Watch

### PostgreSQL 17 → 18
- ICU locale provider changes
- Removed deprecated functions
- Query planner improvements (may change performance)
- Extension compatibility (check pgvector, timescaledb if used)

### Grafana 12.4.x
- Check dashboard JSON compatibility
- Verify data source plugins

### Traefik 3.7.5
- Review TLS configuration changes
- Check middleware compatibility

---

## Files to Update

### 1. renovate.json
- Add PostgreSQL major-version blocking rule
- Add stack labels for new services
- Consider adding Redis/Valkey global rules

### 2. scripts/check-renovate.sh
- Create validation script to detect:
  - Uncovered compose files
  - Major version updates pending
  - Postgres instances needing migration

### 3. STANDARDS.md
- Document PostgreSQL upgrade procedure
- Add stack labeling requirements
- Define breaking change review process
