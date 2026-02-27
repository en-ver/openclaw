include .env
export

.PHONY: help init update setup build onboard configure up down restart logs cert cert-renew devices-list devices-approve token openclaw

help:
	@echo "OpenClaw Deployment Commands:"
	@echo ""
	@echo "  Setup:"
	@echo "    make init           Initialize git submodule"
	@echo "    make setup          Create directories, copy templates, fix permissions"
	@echo "    make build          Build Docker images"
	@echo "    make onboard        Run first-time onboarding wizard"
	@echo ""
	@echo "  Run:"
	@echo "    make up             Start containers"
	@echo "    make down           Stop containers"
	@echo "    make restart        Restart containers"
	@echo "    make logs           Follow container logs"
	@echo ""
	@echo "  Configuration:"
	@echo "    make configure      Reconfigure settings (providers, channels, etc.)"
	@echo "    make token          Show the gateway token"
	@echo ""
	@echo "  Devices:"
	@echo "    make devices-list   List pending device pairing requests"
	@echo "    make devices-approve ID=<requestId>"
	@echo ""
	@echo "  SSL:"
	@echo "    make cert           Generate SSL cert (DOMAIN=your-domain.com)"
	@echo "    make cert-renew     Renew SSL certificates"
	@echo ""
	@echo "  CLI (pass-through to openclaw CLI):"
	@echo "    make openclaw ARGS='<command>'   Run any openclaw CLI command"
	@echo "    Examples:"
	@echo "      make openclaw ARGS='pairing approve telegram <CODE>'"
	@echo "      make openclaw ARGS='models list --all'"
	@echo "      make openclaw ARGS='channels status'"
	@echo "      make openclaw ARGS='config get gateway.auth.mode'"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make update         Update OpenClaw to latest"

init:
	git submodule update --init --recursive

update:
	git submodule update --remote openclaw

setup:
	@echo "Creating directories..."
	mkdir -p .openclaw/workspace .openclaw/identity oauth2-proxy
	@echo "Copying template files (skipping if exists)..."
	@if [ ! -f .env ]; then cp .env.template .env && echo "  Created .env"; fi
	@if [ ! -f .openclaw/openclaw.json ]; then cp .openclaw/openclaw.json.template .openclaw/openclaw.json && echo "  Created .openclaw/openclaw.json"; fi
	@if [ ! -f oauth2-proxy/authenticated-emails.txt ]; then cp oauth2-proxy/authenticated-emails.txt.template oauth2-proxy/authenticated-emails.txt && echo "  Created oauth2-proxy/authenticated-emails.txt"; fi
	@echo "Setting permissions for container user (UID 1000)..."
	@sudo chown -R 1000:1000 .openclaw oauth2-proxy
	@echo ""
	@echo "Setup complete."
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit .env with your values"
	@echo "  2. Edit oauth2-proxy/authenticated-emails.txt with allowed email addresses"
	@echo "  3. Run 'make build'"
	@echo "  4. Run 'make onboard' (first time) or 'make configure' (reconfigure)"
	@echo "  5. Prepare nginx for cert (see README)"
	@echo "  6. Run 'make up' then 'make cert'"

build:
	docker compose build

onboard:
	docker compose run --rm openclaw-cli onboard --no-install-daemon

configure:
	docker compose run --rm openclaw-cli configure

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

cert:
	docker compose run --rm certbot certonly --webroot -w /var/www/html -d $(DOMAIN)

cert-renew:
	docker compose run --rm certbot renew
	docker compose exec nginx nginx -s reload

token:
	@docker compose exec openclaw-gateway node -e "const cfg=JSON.parse(require('fs').readFileSync('/home/node/.openclaw/openclaw.json','utf8'));console.log(cfg.gateway?.auth?.token||'not set')"

openclaw:
	docker compose run --rm openclaw-cli $(ARGS)

devices-list:
	docker compose exec openclaw-gateway node dist/index.js devices list

devices-approve:
	docker compose exec openclaw-gateway node dist/index.js devices approve $(ID)

.DEFAULT_GOAL := help
