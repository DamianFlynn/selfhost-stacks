#!/bin/bash
# Quick diagnostic to check Traefik and container health

echo "=== Quick Server Health Check ==="

# Check Traefik is running
echo -n "Traefik: "
if ssh root@172.16.1.159 "docker ps --format '{{.Names}}' | grep -q '^traefik$'"; then
    echo "✅ Running"
    # Check if it's healthy
    STATUS=$(ssh root@172.16.1.159 "docker inspect traefik --format='{{.State.Health.Status}}' 2>/dev/null || echo 'no healthcheck'")
    echo "  Health: $STATUS"
else
    echo "❌ Not running"
fi

# Check Authelia
echo -n "Authelia: "
if ssh root@172.16.1.159 "docker ps --format '{{.Names}}' | grep -q '^authelia$'"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

# Count containers
RUNNING=$(ssh root@172.16.1.159 "docker ps -q | wc -l" | tr -d ' ')
echo "Containers running: $RUNNING"

# Check for unhealthy
UNHEALTHY=$(ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy | wc -l" | tr -d ' ')
if [ "$UNHEALTHY" -gt 0 ]; then
    echo "⚠️  Unhealthy containers: $UNHEALTHY"
    ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy"
else
    echo "✅ No unhealthy containers"
fi

# Try to curl Traefik dashboard
echo -n "Traefik dashboard: "
if ssh root@172.16.1.159 "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/dashboard/" | grep -q "200"; then
    echo "✅ Accessible (HTTP 200)"
else
    echo "❌ Not accessible"
fi
