# OAuth2 Proxy Setup

This deployment uses [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) with Google authentication to protect the Control UI dashboard.

## Prerequisites

- Google Cloud account
- Domain: configured in `.env` as `DOMAIN`

## Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create or select a project
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. If prompted, configure the OAuth consent screen first:
   - User Type: External
   - App name: `OpenClaw Gateway`
   - User support email: your email
   - Developer contact: your email
6. For OAuth client ID:
   - Application type: **Web application**
   - Name: `OpenClaw Dashboard`
   - Authorized JavaScript origins: `https://<your-domain>`
   - Authorized redirect URIs: `https://<your-domain>/oauth2/callback`
7. Click **Create**
8. Copy the **Client ID** and **Client Secret**

## Step 2: Generate Cookie Secret

```bash
openssl rand -base64 32 | tr -- '+/' '-_'
```

## Step 3: Configure Environment

Add to `.env`:

```bash
OAUTH2_PROXY_CLIENT_ID=<your-client-id>
OAUTH2_PROXY_CLIENT_SECRET=<your-client-secret>
OAUTH2_PROXY_COOKIE_SECRET=<generated-secret>
```

## Step 4: Configure Allowed Emails

Create `oauth2-proxy/authenticated-emails.txt` with one email per line:

```
your-email@gmail.com
another-user@gmail.com
```

## Step 5: Deploy

```bash
make up
```

## How It Works

```
┌─────────┐     ┌───────┐     ┌──────────────┐     ┌──────────────────┐
│ Browser │────▶│ nginx │────▶│ oauth2-proxy │────▶│ openclaw-gateway │
└─────────┘     └───────┘     └──────────────┘     └──────────────────┘
                     │               │
                     │               ▼
                     │        ┌──────────────┐
                     └───────▶│ Google OAuth │
                              └──────────────┘
```

1. User accesses `https://<your-domain>/dashboard`
2. nginx delegates auth to oauth2-proxy via `auth_request`
3. If not authenticated, redirects to Google login
4. After Google auth, checks email against whitelist
5. If authorized, proxies request to openclaw-gateway

## Endpoints

| Path | Description |
|------|-------------|
| `/dashboard` | Protected Control UI (requires Google auth) |
| `/dashboard/*` | Protected Control UI paths |
| `/oauth2/sign_in` | Initiate Google login |
| `/oauth2/callback` | OAuth callback (Google redirects here) |
| `/oauth2/sign_out` | Sign out |
| `/` | Gateway endpoint (node connections, no auth) |

## Troubleshooting

### "Login Failed" error
- Verify Client ID and Secret in `.env`
- Check redirect URI matches exactly in Google Console

### "Email not authorized" error
- Add email to `oauth2-proxy/authenticated-emails.txt`
- Restart: `docker compose restart oauth2-proxy`

### Cookie issues
- Ensure `OAUTH2_PROXY_COOKIE_SECRET` is set
- Clear browser cookies for the domain

## Reference

- [oauth2-proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Google OAuth Provider](https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/google)
