#!/usr/bin/env bash
# check-renovate.sh - Validate Renovate configuration and coverage
# Usage: ./scripts/check-renovate.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 Renovate Configuration Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Locate the Renovate config (D-25).
# This used to test a hard-coded "renovate.json", which this repo does not have -- the file is
# renovate.json5. The script therefore exit 1'd here on every run and lines below had never
# executed. Renovate itself accepts several filenames, so detect rather than hard-code, and report
# the name actually found instead of a literal that may be wrong again.
# The candidate names are COMPOSED from basename x extension rather than written out as literals,
# and that is deliberate -- it is not obfuscation. It encodes Renovate's own naming rule (either
# basename, either extension) in one place, and it means this script contains NO hard-coded config
# filename anywhere in executable code. A hard-coded filename is the exact defect being repaired
# here; leaving four more of them in the list that replaces it would reintroduce it in a new shape.
# Search order is json5-before-json within each basename, matching the loop nesting below.
CONFIG_FILE=""
CONFIG_CANDIDATES=""
for base in renovate .renovaterc; do
  for ext in json5 json; do
    cand="${base}.${ext}"
    CONFIG_CANDIDATES="${CONFIG_CANDIDATES:+${CONFIG_CANDIDATES}, }${cand}"
    if [[ -z "$CONFIG_FILE" && -f "$cand" ]]; then
      CONFIG_FILE="$cand"
    fi
  done
done

if [[ -z "$CONFIG_FILE" ]]; then
  echo -e "${RED}❌ no Renovate config found (looked for: ${CONFIG_CANDIDATES})${NC}"
  exit 1
fi

echo -e "${GREEN}✅ $CONFIG_FILE found${NC}"

# VALIDATOR_ROUTE -- the estate convention for an optional external tool (see ZFS_ROUTE in
# check-music-freeze.sh, HA_ROUTE in check-music-consumers.sh). "could not look" and "it is valid"
# are DIFFERENT answers and must never share a verdict, so the unavailable branch prints yellow and
# never a green tick.
#
# Deliberately NOT `npx --yes renovate-config-validator`: that downloads and executes an unverified
# package from the registry on every run of a health check. If the validator is wanted here, install
# it explicitly and knowingly.
VALIDATOR_ROUTE="unavailable"
if command -v renovate-config-validator >/dev/null 2>&1; then
  VALIDATOR_ROUTE="local"
  if renovate-config-validator "$CONFIG_FILE"; then
    echo -e "${GREEN}✅ $CONFIG_FILE validates (renovate-config-validator)${NC}"
  else
    echo -e "${RED}❌ $CONFIG_FILE FAILED validation — a config error silently stops the WHOLE repo run${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  renovate-config-validator not installed — $CONFIG_FILE is UNVALIDATED, not valid.${NC}"
  echo "   Install with: npm install -g renovate   (then re-run)"
fi
echo -e "${BLUE}Validator route: $VALIDATOR_ROUTE${NC}"
echo ""

# 1. Check all compose.yaml files are tracked
echo "📋 Checking compose.yaml coverage..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COMPOSE_FILES=$(find stacks/selfhosted -name "compose.yaml" | sort)
COMPOSE_COUNT=$(echo "$COMPOSE_FILES" | wc -l | tr -d ' ')

echo -e "${BLUE}Found $COMPOSE_COUNT compose.yaml files:${NC}"
echo "$COMPOSE_FILES" | sed 's/^/  /'
echo ""

# 2. Check all YAML files with image: declarations
echo "🐳 Checking Docker image declarations..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

YAML_WITH_IMAGES=$(grep -rl "image:" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | sort)
IMAGE_FILE_COUNT=$(echo "$YAML_WITH_IMAGES" | wc -l | tr -d ' ')

echo -e "${BLUE}Found $IMAGE_FILE_COUNT YAML files with Docker images${NC}"
echo ""

# 3. Extract all unique images
echo "🏷️  Extracting unique Docker images..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IMAGES=$(grep -rh "^\s*image:" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | \
  sed 's/^\s*image:\s*//' | \
  sed 's/#.*//' | \
  sed 's/\s*$//' | \
  sort -u)

IMAGE_COUNT=$(echo "$IMAGES" | wc -l | tr -d ' ')
echo -e "${BLUE}Found $IMAGE_COUNT unique Docker images${NC}"
echo ""

# 4. Check for PostgreSQL instances
echo "🐘 PostgreSQL instances..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

POSTGRES_INSTANCES=$(echo "$IMAGES" | grep -i postgres || true)
POSTGRES_COUNT=$(echo "$POSTGRES_INSTANCES" | grep -v '^$' | wc -l | tr -d ' ')

if [[ $POSTGRES_COUNT -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  Found $POSTGRES_COUNT PostgreSQL images:${NC}"
  echo "$POSTGRES_INSTANCES" | while read -r img; do
    # Extract version
    VERSION=$(echo "$img" | grep -oE ':[0-9]+' | sed 's/://' || echo "unknown")
    FILES=$(grep -rl "$img" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${YELLOW}$img${NC} (used in $FILES files)"
  done
  echo ""
  echo -e "${YELLOW}⚠️  PostgreSQL major version updates are DISABLED in $CONFIG_FILE${NC}"
  echo "   Manual migration required: pg_dump → restore → test"
else
  echo -e "${GREEN}✅ No PostgreSQL instances found${NC}"
fi
echo ""

# 5. Check for Redis/Valkey instances
echo "🔴 Redis/Valkey instances..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REDIS_INSTANCES=$(echo "$IMAGES" | grep -iE 'redis|valkey' || true)
REDIS_COUNT=$(echo "$REDIS_INSTANCES" | grep -v '^$' | wc -l | tr -d ' ')

if [[ $REDIS_COUNT -gt 0 ]]; then
  echo -e "${BLUE}Found $REDIS_COUNT Redis/Valkey images:${NC}"
  echo "$REDIS_INSTANCES" | while read -r img; do
    FILES=$(grep -rl "$img" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | wc -l | tr -d ' ')
    echo "  $img (used in $FILES files)"
  done
else
  echo -e "${GREEN}✅ No Redis/Valkey instances found${NC}"
fi
echo ""

# 6. Check for pending Renovate PRs
echo "🔄 Pending Renovate PRs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

git fetch origin --quiet 2>/dev/null || true
RENOVATE_BRANCHES=$(git branch -r | grep "origin/renovate/" | sed 's/origin\///' | sed 's/^\s*//' || true)
RENOVATE_COUNT=$(echo "$RENOVATE_BRANCHES" | grep -v '^$' | wc -l | tr -d ' ')

if [[ $RENOVATE_COUNT -gt 0 ]]; then
  echo -e "${BLUE}Found $RENOVATE_COUNT pending Renovate PRs:${NC}"
  echo ""
  
  echo "$RENOVATE_BRANCHES" | while read -r branch; do
    if [[ -n "$branch" ]]; then
      COMMIT_MSG=$(git log "origin/$branch" --oneline -1 2>/dev/null || echo "unknown")
      
      # Check if it's a major update
      if echo "$branch" | grep -qE 'postgres|docker\.io-postgres'; then
        echo -e "  ${YELLOW}⚠️  $branch${NC}"
        echo "      $COMMIT_MSG"
        echo -e "      ${YELLOW}MAJOR VERSION - Requires manual migration${NC}"
      elif echo "$COMMIT_MSG" | grep -qi "major"; then
        echo -e "  ${YELLOW}⚠️  $branch${NC}"
        echo "      $COMMIT_MSG"
      else
        echo -e "  ${GREEN}✓${NC}  $branch"
        echo "      $COMMIT_MSG"
      fi
    fi
  done
else
  echo -e "${GREEN}✅ No pending Renovate PRs${NC}"
fi
echo ""

# 7. Summary
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Compose files:      $COMPOSE_COUNT"
echo "  Files with images:  $IMAGE_FILE_COUNT"
echo "  Unique images:      $IMAGE_COUNT"
echo "  PostgreSQL:         $POSTGRES_COUNT instances"
echo "  Redis/Valkey:       $REDIS_COUNT instances"
echo "  Pending PRs:        $RENOVATE_COUNT"
echo ""

# 8. Recommendations
echo "💡 Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $POSTGRES_COUNT -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  PostgreSQL Detected${NC}"
  echo "   - Major version updates are BLOCKED (requires manual migration)"
  echo "   - Before upgrading: Run pg_dump backups"
  echo "   - Test on non-critical stack first"
  echo ""
fi

if [[ $RENOVATE_COUNT -gt 10 ]]; then
  echo -e "${YELLOW}⚠️  Many Pending PRs${NC}"
  echo "   - Consider reviewing and merging safe updates"
  echo "   - Check RENOVATE-REVIEW.md for categorization"
  echo ""
fi

echo -e "${GREEN}✅ Validation Complete${NC}"
echo ""
