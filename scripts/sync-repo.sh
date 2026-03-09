#!/bin/bash
set -e

echo "=== Syncing Repository ==="
echo

# Pull latest changes locally
echo "📥 Pulling latest changes locally..."
git pull
echo

# Check what commit we're on
CURRENT_COMMIT=$(git rev-parse --short HEAD)
echo "✅ Local at commit: $CURRENT_COMMIT"
echo

# Pull on server
echo "📥 Pulling changes on server 172.16.1.159..."
ssh root@172.16.1.159 "cd /mnt/fast/stacks && git pull"
echo

# Check server commit
SERVER_COMMIT=$(ssh root@172.16.1.159 "cd /mnt/fast/stacks && git rev-parse --short HEAD")
echo "✅ Server at commit: $SERVER_COMMIT"
echo

if [ "$CURRENT_COMMIT" = "$SERVER_COMMIT" ]; then
    echo "✅ Local and server are in sync!"
else
    echo "⚠️  Warning: Local ($CURRENT_COMMIT) and server ($SERVER_COMMIT) are out of sync"
fi
