# OpenClaw Deployment

Self-hosted OpenClaw Gateway deployment behind Nginx reverse proxy with HTTPS. OpenClaw runs in Docker and is accessible via a custom domain with Let's Encrypt SSL certificates.

**Tested on:** Debian + Docker

## Scope

This deployment covers only the **OpenClaw Gateway** (the "brain"). To manage your local machine, you need to install OpenClaw on it as a node and connect to this gateway.

The gateway integrates with messengers, workstations, and other node types.

**Documentation:**
- [Architecture](https://docs.openclaw.ai/concepts/architecture)
- [Gateway](https://docs.openclaw.ai/cli/gateway)
- [Nodes](https://docs.openclaw.ai/nodes)
- [macOS App](https://docs.openclaw.ai/start/onboarding) - connect your Mac to the gateway

## Prerequisites

- Docker and Docker Compose installed
- A domain name pointing to your server's IP address
- Ports 80 and 443 open on your firewall

## Setup

### 1. Clone the repository

```bash
git clone git@github.com:en-ver/openclaw.git
cd openclaw
```

### 2. Copy template files

```bash
cp .env.template .env
cp .openclaw/openclaw.json.template .openclaw/openclaw.json
```

### 3. Configure secrets

Edit `.env`:
- Set `DOMAIN` to your domain (e.g., `openclaw.example.com`)
- Generate secrets:
  ```bash
  # Gateway token
  openssl rand -hex 24
  
  # Session keys (run 3 times)
  openssl rand -hex 32
  ```
- Set `OPENCLAW_GATEWAY_TOKEN`, `CLAUDE_WEB_COOKIE`, `CLAUDE_AI_SESSION_KEY`, `CLAUDE_WEB_SESSION_KEY`
- Set `GOG_KEYRING_PASSWORD`

### 4. Generate HTTP Basic Auth password

```bash
docker run --rm httpd:alpine htpasswd -nbB admin "your-password" > nginx/.htpasswd
```

### 5. Update OpenClaw configuration

Edit `.openclaw/openclaw.json`:
- Set `gateway.controlUi.allowedOrigins` to `["https://your-domain.com"]`

### 6. Prepare nginx for initial certificate generation

Edit `nginx/templates/default.conf.template`:
- Comment out the entire HTTPS server block
- Comment out the HTTP-to-HTTPS redirect in the HTTP server block

### 7. Initialize and start containers

```bash
make init
make build up
```

### 8. Generate SSL certificate

```bash
make cert DOMAIN=your-domain.com
```

### 9. Enable HTTPS in nginx

Edit `nginx/templates/default.conf.template`:
- Uncomment the HTTPS server block
- Uncomment the HTTP-to-HTTPS redirect

Restart nginx:

```bash
docker compose restart nginx
```

### 10. First-time Control UI Setup

After deployment, you must authorize your browser to access the Control UI.

**Step 1: Connect from browser**

1. Open `https://your-domain.com/overview` in a browser
2. In the **Gateway Access** section, find the token input field
3. Enter your gateway token (the value of `OPENCLAW_GATEWAY_TOKEN` from `.env`)
4. Click **Connect**

**Step 2: Approve the pairing request**

You'll see "pairing required" - this is expected for security. Remote connections require explicit approval.

Run these commands on the server:

```bash
# List pending pairing requests
docker compose exec openclaw-gateway node dist/index.js devices list
```

You'll see output like:

```
Pending (1)
┌──────────────────────────────────────┬──────────────────────────────────┬──────────┐
│ Request                              │ Device                           │ Role     │
├──────────────────────────────────────┼──────────────────────────────────┼──────────┤
│ a1b2c3d4-e5f6-7890-abcd-ef1234567890 │ abc123def456...                  │ operator │
└──────────────────────────────────────┴──────────────────────────────────┴──────────┘
```

Copy the **Request** ID and approve it:

```bash
# Approve by request ID
docker compose exec openclaw-gateway node dist/index.js devices approve <requestId>
```

Or use the Makefile shortcut:

```bash
make devices-approve ID=<requestId>
```

**Step 3: Verify connection**

Refresh the browser page. The Control UI should now show **Connected** status.

**Notes:**
- Each browser/device needs separate approval
- Local connections (`127.0.0.1`) are auto-approved
- You can use `make devices-list` to check pending requests

### 11. Configure Control UI Base Path

To protect the Control UI dashboard with HTTP Basic Auth, configure the base path:

1. Open `https://your-domain.com/config` in your browser
2. Find **Gateway** → **Control UI** → **Control UI Base Path**
3. Set it to `/dashboard`
4. Click **Save**

This routes the dashboard through the `/dashboard` location in nginx, which is protected by Basic Auth. The root location (`/`) remains unprotected for WebSocket connections from nodes.

**Access URLs after this change:**
- Dashboard (Basic Auth protected): `https://your-domain.com/dashboard`
- WebSocket endpoint (for nodes): `wss://your-domain.com/`

### 12. Node Configuration

When connecting nodes to this gateway, use port 443 (HTTPS) instead of the default gateway port (18789):

```
Gateway URL: wss://your-domain.com/
```

The nginx reverse proxy handles SSL termination and forwards WebSocket connections to the gateway container.

**Note:** The default port 18789 documented in OpenClaw docs is not exposed publicly in this deployment. All external access goes through nginx on port 443.

## Commands

Run `make` to see available commands:

| Command | Description |
|---------|-------------|
| `make init` | Initialize git submodule |
| `make update` | Update OpenClaw to latest |
| `make build` | Build Docker images |
| `make up` | Start containers |
| `make down` | Stop containers |
| `make restart` | Restart containers |
| `make logs` | Follow container logs |
| `make cert DOMAIN=x` | Generate SSL certificate |
| `make cert-renew` | Renew SSL certificates |
| `make devices-list` | List pending device pairing requests |
| `make devices-approve ID=x` | Approve device pairing request |

## SSL Certificate Renewal

```bash
0 0 1 * * cd /path/to/openclaw && make cert-renew
```

## Updating OpenClaw

```bash
make update
make build up
```
