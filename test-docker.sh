#!/usr/bin/env bash
# OpenClaw Docker Simple Test
set -e

echo "==================================="
echo "OpenClaw Docker Simple Test"
echo "==================================="

GREEN='\033[0;32m'
NC='\033[0m'
success() { echo -e "${GREEN}✓${NC} $1"; }

echo ""
echo "Step 1: Checking Docker..."
docker --version > /dev/null && success "Docker OK"
docker compose version > /dev/null && success "Docker Compose OK"

echo ""
echo "Step 2: Creating .env..."
cat > .env << 'EOF'
OPENCLAW_IMAGE=openclaw:local
OPENCLAW_GATEWAY_TOKEN=
OPENCLAW_CONFIG_DIR=${HOME}/.openclaw
OPENCLAW_WORKSPACE_DIR=${HOME}/.openclaw/workspace
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=loopback
EOF
success ".env created"

echo ""
echo "Step 3: Creating directory..."
mkdir -p "$HOME/.openclaw"
success "Directory created"

echo ""
echo "Step 4: Building image..."
docker build -t openclaw:local . && success "Image built"

echo ""
echo "Step 5: Starting gateway..."
docker compose down 2>/dev/null || true
docker compose up -d openclaw-gateway && success "Gateway started"

echo ""
echo "Step 6: Waiting..."
sleep 5

if docker compose ps | grep -q "openclaw-gateway.*running"; then
    success "Gateway is running"
fi

echo ""
echo "==================================="
success "Setup Complete!"
echo "==================================="
echo "Gateway: http://127.0.0.1:18789"
echo "Config: $HOME/.openclaw"
echo ""
