#!/bin/bash
# Check server and container health

echo "=== Checking Server Health ==="
echo

# Check if we can reach the server
if ! ssh -q root@172.16.1.159 exit; then
    echo "❌ Cannot connect to server 172.16.1.159"
    exit 1
fi

echo "✅ Server reachable"
echo

# Get repository sync status
echo "=== Repository Sync Status ==="
ssh root@172.16.1.159 "cd /mnt/fast/stacks && git fetch && git status -sb"
echo

# Check Traefik
echo "=== Traefik Status ==="
ssh root@172.16.1.159 "docker ps -a --filter 'name=traefik' --format 'Name: {{.Names}}\nStatus: {{.Status}}\nPorts: {{.Ports}}'"
echo

# Check Authelia
echo "=== Authelia Status ==="
ssh root@172.16.1.159 "docker ps -a --filter 'name=authelia' --format 'Name: {{.Names}}\nStatus: {{.Status}}\nPorts: {{.Ports}}'"
echo

# Check all unhealthy containers
echo "=== Unhealthy Containers ==="
ssh root@172.16.1.159 "docker ps --format '{{.Names}}\t{{.Status}}' | grep -i unhealthy || echo 'No unhealthy containers'"
echo

# Check recently exited containers
echo "=== Recently Exited Containers ==="
ssh root@172.16.1.159 "docker ps -a --filter 'status=exited' --format '{{.Names}}\t{{.Status}}' | head -10 || echo 'No exited containers'"
echo

# Test Traefik endpoint
echo "=== Testing Traefik Dashboard ==="
ssh root@172.16.1.159 "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:8080/dashboard/ || echo 'Failed to reach Traefik'"
echo

# Check network connectivity
echo "=== Network Status ==="
ssh root@172.16.1.159 "docker network ls | grep t3_proxy"
echo

echo "=== Container Count ==="
RUNNING=$(ssh root@172.16.1.159 "docker ps -q | wc -l")
TOTAL=$(ssh root@172.16.1.159 "docker ps -aq | wc -l")
echo "Running: $RUNNING / Total: $TOTAL"
