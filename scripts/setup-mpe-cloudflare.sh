#!/usr/bin/env bash
# setup-mpe-cloudflare.sh — create the MPE Cloudflare Tunnel + DNS (cert approach "a").
#
# Creates a remotely-managed tunnel "mpe", points its public hostnames at the
# in-LXC Traefik (http://mpe-traefik:80), creates the proxied DNS records, and
# prints the TUNNEL_TOKEN to paste into stacks/mpe/edge/.env.
#
# Cloudflare terminates public TLS at the edge; nothing else is needed in Traefik.
#
# Requirements (export before running):
#   CF_API_TOKEN   API token with: Account > Cloudflare Tunnel:Edit
#                                   Zone    > DNS:Edit   (zone diginerve.net)
#   CF_ACCOUNT_ID  Cloudflare account id
#   CF_ZONE_ID     Zone id for diginerve.net
# Optional:
#   TUNNEL_NAME    (default: mpe)
#   HOSTS          (default: "mpe-erp mpe-n8n mpe-shop")  flat hosts under diginerve.net
#   ORIGIN         (default: http://mpe-traefik:80)
#
# ⚠️  This script CREATES live Cloudflare resources. Review, then run deliberately.
# Idempotent: re-running reuses an existing tunnel of the same name.
set -euo pipefail

: "${CF_API_TOKEN:?set CF_API_TOKEN}"
: "${CF_ACCOUNT_ID:?set CF_ACCOUNT_ID}"
: "${CF_ZONE_ID:?set CF_ZONE_ID}"
TUNNEL_NAME="${TUNNEL_NAME:-mpe}"
HOSTS="${HOSTS:-mpe-erp mpe-n8n mpe-shop}"
ORIGIN="${ORIGIN:-http://mpe-traefik:80}"
BASE="diginerve.net"
API="https://api.cloudflare.com/client/v4"
auth=(-H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")

api() { curl -fsS "${auth[@]}" "$@"; }

echo "==> Looking up existing tunnel '${TUNNEL_NAME}'..."
tunnel_id="$(api "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?name=${TUNNEL_NAME}&is_deleted=false" \
  | jq -r '.result[0].id // empty')"

if [[ -z "${tunnel_id}" ]]; then
  echo "==> Creating tunnel '${TUNNEL_NAME}'..."
  resp="$(api -X POST "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel" \
    --data "$(jq -n --arg n "$TUNNEL_NAME" '{name:$n, config_src:"cloudflare"}')")"
  tunnel_id="$(echo "$resp" | jq -r '.result.id')"
else
  echo "==> Reusing existing tunnel id ${tunnel_id}"
fi
echo "    tunnel_id=${tunnel_id}"

echo "==> Writing tunnel ingress config..."
ingress='[]'
for h in ${HOSTS}; do
  ingress="$(jq -n --argjson cur "$ingress" --arg host "${h}.${BASE}" --arg svc "$ORIGIN" \
    '$cur + [{hostname:$host, service:$svc}]')"
done
ingress="$(jq -n --argjson cur "$ingress" '$cur + [{service:"http_status:404"}]')"
api -X PUT "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${tunnel_id}/configurations" \
  --data "$(jq -n --argjson ing "$ingress" '{config:{ingress:$ing}}')" >/dev/null

echo "==> Creating proxied DNS CNAMEs -> ${tunnel_id}.cfargotunnel.com ..."
for h in ${HOSTS}; do
  fqdn="${h}.${BASE}"
  rec_id="$(api "${API}/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=${fqdn}" | jq -r '.result[0].id // empty')"
  body="$(jq -n --arg n "$fqdn" --arg c "${tunnel_id}.cfargotunnel.com" \
    '{type:"CNAME", name:$n, content:$c, proxied:true}')"
  if [[ -z "$rec_id" ]]; then
    api -X POST "${API}/zones/${CF_ZONE_ID}/dns_records" --data "$body" >/dev/null
    echo "    created ${fqdn}"
  else
    api -X PUT "${API}/zones/${CF_ZONE_ID}/dns_records/${rec_id}" --data "$body" >/dev/null
    echo "    updated ${fqdn}"
  fi
done

echo "==> Fetching tunnel token..."
token="$(api "${API}/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${tunnel_id}/token" | jq -r '.result')"

cat <<EOF

✅ Done. Tunnel '${TUNNEL_NAME}' (${tunnel_id}) routes:
$(for h in ${HOSTS}; do echo "   https://${h}.${BASE}  ->  ${ORIGIN}"; done)

Add this to stacks/mpe/edge/.env (DO NOT COMMIT):

TUNNEL_TOKEN=${token}

Then: docker compose -f stacks/mpe/edge/compose.yaml up -d
EOF
