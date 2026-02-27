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

## Authentication

- **Dashboard (`/dashboard`)**: Protected by Google OAuth (see [OAUTH2_PROXY.md](OAUTH2_PROXY.md))
- **Gateway endpoint (`/`)**: No authentication (for node WebSocket connections)

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

### 2. Initialize submodule

```bash
make init
```

### 3. Run setup

Create directories, copy template files, and fix permissions:

```bash
make setup
```

**Note:** `make setup` requires `sudo` to set directory ownership to UID 1000 (the container's `node` user). This ensures the OpenClaw container can write to `.openclaw/` and `oauth2-proxy/` directories.

### 4. Configure secrets

Edit `.env`:
- Set `DOMAIN` to your domain (e.g., `openclaw.example.com`)
- Set `GOG_KEYRING_PASSWORD` — generate with: `openssl rand -hex 32`

### 5. Configure OAuth2 Proxy

Follow the instructions in [OAUTH2_PROXY.md](OAUTH2_PROXY.md) to:
1. Create Google OAuth credentials
2. Generate cookie secret
3. Add allowed email addresses

### 6. Build images

```bash
make build
```

### 7. Run onboarding

Run the first-time onboarding wizard to configure LLM providers, gateway settings, and workspace:

```bash
make onboard
```

See [Configuration Wizard docs](https://docs.openclaw.ai/start/wizard) for details.

### 8. Prepare nginx for initial certificate generation (temporary)

Edit `nginx/templates/default.conf.template`:
- Comment out the entire HTTPS server block
- Comment out the HTTP-to-HTTPS redirect in the HTTP server block

### 9. Start containers

```bash
make up
```

### 10. Generate SSL certificate

```bash
make cert DOMAIN=your-domain.com
```

### 11. Enable HTTPS in nginx

Edit `nginx/templates/default.conf.template`:
- Uncomment the HTTPS server block
- Uncomment the HTTP-to-HTTPS redirect

Restart nginx:

```bash
docker compose restart nginx
```

### 12. First-time Control UI Setup

After deployment, you must authorize your browser to access the Control UI.

**Step 1: Connect from browser**

1. Get your gateway token:
   ```bash
   make token
   ```
2. Open `https://your-domain.com/dashboard` in a browser
3. In the **Gateway Access** section, find the token input field
4. Enter the token from step 1
5. Click **Connect**

**Step 2: Approve the pairing request**

You'll see "pairing required" - this is expected for security. Remote connections require explicit approval.

```bash
# List pending pairing requests
make devices-list
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
make devices-approve ID=<requestId>
```

**Step 3: Verify connection**

Refresh the browser page. The Control UI should now show **Connected** status.

**Notes:**
- Each browser/device needs separate approval
- Local connections (`127.0.0.1`) are auto-approved
- You can use `make devices-list` to check pending requests

### 13. Reconfigure (optional)

To add more LLM providers, configure channels, or change other settings after initial setup:

```bash
make configure
```

You can also run any openclaw CLI command using the generic pass-through:

```bash
# Configure only model providers
make openclaw ARGS='configure --section model'

# Approve a Telegram pairing request
make openclaw ARGS='pairing approve telegram <CODE>'

# List channels and their status
make openclaw ARGS='channels status'

# List all available models
make openclaw ARGS='models list --all'
```

See [CLI Reference](https://docs.openclaw.ai/cli) for the full list of available commands.

### 14. Node Configuration

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
| `make setup` | Create directories, copy templates, fix permissions |
| `make build` | Build Docker images |
| `make onboard` | Run first-time onboarding wizard |
| `make configure` | Reconfigure settings (providers, channels, etc.) |
| `make up` | Start containers |
| `make down` | Stop containers |
| `make restart` | Restart containers |
| `make logs` | Follow container logs |
| `make token` | Show the gateway token |
| `make cert DOMAIN=x` | Generate SSL certificate |
| `make cert-renew` | Renew SSL certificates |
| `make openclaw ARGS='...'` | Run any openclaw CLI command |
| `make devices-list` | List pending device pairing requests |
| `make devices-approve ID=x` | Approve device pairing request |

## SSL Certificate Renewal

```bash
0 0 1 * * cd /path/to/openclaw && make cert-renew
```

## Updating OpenClaw

```bash
make update
make build
make up
```
