# OpenClaw Deployment

Self-hosted OpenClaw Gateway deployment behind Nginx reverse proxy with HTTPS. OpenClaw runs in Docker and is accessible via a custom domain with Let's Encrypt SSL certificates.

**Tested on:** Debian + Docker

## Quick Start

1. **Copy template files and configure secrets:**
   ```bash
   cp .env.template .env
   cp .openclaw/openclaw.json.template .openclaw/openclaw.json
   ```

2. **Edit `.env` with your values:**
   - Generate a secure token: `openssl rand -hex 24`
   - Set `OPENCLAW_GATEWAY_TOKEN` to this value
   - Configure other secrets as needed

3. **Generate HTTP Basic Auth password:**
   ```bash
   htpasswd -c nginx/.htpasswd admin
   ```
   Or using Docker:
   ```bash
   docker run --rm httpd:alpine htpasswd -nbB admin "your-password" > nginx/.htpasswd
   ```

4. **Update `openclaw.json`:**
   - Set `gateway.controlUi.allowedOrigins` to your domain
   - Ensure `gateway.auth.token` matches `OPENCLAW_GATEWAY_TOKEN` in `.env`

5. **Initialize submodule:**
   ```bash
   git submodule update --init --recursive
   ```

6. **Build and start:**
   ```bash
   docker compose up -d --build
   ```

## SSL Certificates

First-time certificate generation:
```bash
docker compose run --rm certbot certonly --webroot -w /var/www/certbot -d your-domain.com
```

Renewal (set up cron):
```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## Updating OpenClaw

```bash
git submodule update --remote openclaw
docker compose up -d --build
```

## Files

| File | Description |
|------|-------------|
| `docker-compose.yml` | Main deployment configuration |
| `.env.template` | Environment template (tracked) |
| `.env` | Environment secrets (not tracked) |
| `.openclaw/openclaw.json.template` | OpenClaw config template (tracked) |
| `.openclaw/openclaw.json` | OpenClaw configuration (not tracked) |
| `nginx/.htpasswd` | HTTP Basic Auth credentials (not tracked) |
| `nginx/templates/default.conf.template` | Nginx reverse proxy config |
