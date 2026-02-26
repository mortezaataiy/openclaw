# OpenClaw Docker Setup

This guide explains how to run OpenClaw using Docker without the docker-setup.sh script.

## Quick Start (Simple - No Token)

For local development without authentication:

```bash
# 1. Create .env file
cp .env.docker .env

# 2. Create base directory (subdirectories created automatically)
mkdir -p ~/.openclaw

# 3. Build image
docker build -t openclaw:local .

# 4. Start gateway
docker-compose up -d openclaw-gateway

# 5. Access gateway
curl http://127.0.0.1:18789/health
```

## Quick Start (Secure - With Token)

For production or when you need authentication:

### 1. Generate Gateway Token

```bash
# Using openssl
openssl rand -hex 32

# Or using Python
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### 2. Create Environment File

```bash
cp .env.docker .env
```

Edit `.env` and set `OPENCLAW_GATEWAY_TOKEN` to the generated token.

### 3. Create Base Directory

```bash
mkdir -p ~/.openclaw
```

Note: Subdirectories (identity, workspace, etc.) are created automatically by the container.

### 4. Build the Image

```bash
docker build -t openclaw:local .
```

### 5. Run the Gateway

```bash
docker-compose up -d openclaw-gateway
```

### 6. Check Status

```bash
docker-compose logs -f openclaw-gateway
```

## Using the CLI

Run interactive CLI commands:

```bash
docker-compose run --rm openclaw-cli --help
```

## Configuration

### Environment Variables

See `.env.docker` for all available configuration options.

Key variables:
- `OPENCLAW_GATEWAY_TOKEN`: Authentication token (optional for loopback, required for lan)
- `OPENROUTER_API_KEY`: OpenRouter API key for AI models (optional)
- `TELEGRAM_BOT_TOKEN`: Telegram bot token for Telegram integration (optional)
- `OPENCLAW_GATEWAY_BIND`: `loopback` for local only (default, no SSL needed), `lan` for external access
- `OPENCLAW_CONFIG_DIR`: Configuration directory (default: `~/.openclaw`)
- `OPENCLAW_WORKSPACE_DIR`: Workspace directory (default: `~/.openclaw/workspace`)

**Security Note**: 
- With `loopback` bind: Gateway only accessible from `127.0.0.1` - token is optional
- With `lan` bind: Gateway accessible from network - token is REQUIRED for security

### Network Access

By default, the gateway binds to `loopback` (127.0.0.1) which:
- Does not require SSL certificates
- Is accessible only from the host machine via `http://127.0.0.1:18789`
- Ports are mapped to `127.0.0.1:18789` and `127.0.0.1:18790` on the host

To access from other machines, you have two options:

1. **Use a reverse proxy** (recommended for production):
   ```bash
   # Example with nginx
   server {
       listen 80;
       location / {
           proxy_pass http://127.0.0.1:18789;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

2. **Change bind to lan** (requires SSL for production):
   - Set `OPENCLAW_GATEWAY_BIND=lan` in `.env`
   - Change port mapping in docker-compose.yml from `"127.0.0.1:18789:18789"` to `"18789:18789"`
   - Gateway will be accessible from network (0.0.0.0)

### Ports

- `18789`: Gateway port (mapped to 127.0.0.1:18789 by default)
- `18790`: Bridge port (mapped to 127.0.0.1:18790 by default)

## Common Commands

```bash
# View logs
docker-compose logs -f openclaw-gateway

# Stop services
docker-compose down

# Restart gateway
docker-compose restart openclaw-gateway

# Run CLI command
docker-compose run --rm openclaw-cli channels status

# Health check (from inside container)
docker-compose exec openclaw-gateway node dist/index.js health --token "YOUR_TOKEN"

# Health check (from host)
curl -H "Authorization: Bearer YOUR_TOKEN" http://127.0.0.1:18789/health
```

## Troubleshooting

### Permission Issues

If you encounter permission issues with mounted volumes, ensure the directories exist and have proper permissions:

```bash
mkdir -p ~/.openclaw/identity ~/.openclaw/workspace
chmod -R 755 ~/.openclaw
```

### Gateway Not Starting

Check logs for errors:
```bash
docker-compose logs openclaw-gateway
```

Verify token is set:
```bash
grep OPENCLAW_GATEWAY_TOKEN .env
```

### Cannot Access Gateway

If you cannot access the gateway from the host:

1. Verify the gateway is running:
   ```bash
   docker-compose ps
   ```

2. Check if ports are properly mapped:
   ```bash
   docker-compose port openclaw-gateway 18789
   ```

3. Test connection:
   ```bash
   curl http://127.0.0.1:18789/health
   ```

### Building with Browser Support

To include Chromium for browser automation (adds ~300MB):

```bash
docker build --build-arg OPENCLAW_INSTALL_BROWSER=1 -t openclaw:local .
```

## Advanced Configuration

### Using with Tailscale

If you want to access the gateway through Tailscale:

1. Keep `OPENCLAW_GATEWAY_BIND=loopback` (no SSL needed)
2. Access via `http://127.0.0.1:18789` from the host
3. Use SSH port forwarding or a reverse proxy to expose to Tailscale network

### Custom Port Mapping

To use different host ports, edit `.env`:

```bash
OPENCLAW_GATEWAY_PORT=8080
OPENCLAW_BRIDGE_PORT=8081
```

The gateway will be accessible at `http://127.0.0.1:8080`
