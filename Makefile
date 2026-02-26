.PHONY: help init update build up down restart logs cert cert-renew devices-list devices-approve

help:
	@echo "OpenClaw Deployment Commands:"
	@echo "  make init           Initialize git submodule"
	@echo "  make update         Update OpenClaw to latest"
	@echo "  make build          Build Docker images"
	@echo "  make up             Start containers"
	@echo "  make down           Stop containers"
	@echo "  make restart        Restart containers"
	@echo "  make logs           Follow container logs"
	@echo "  make cert           Generate SSL cert (DOMAIN=your-domain.com)"
	@echo "  make cert-renew     Renew SSL certificates"
	@echo "  make devices-list   List pending device pairing requests"
	@echo "  make devices-approve ID=<requestId>"

init:
	git submodule update --init --recursive

update:
	git submodule update --remote openclaw

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

cert:
	docker compose run --rm certbot certonly --webroot -w /var/www/certbot -d $(DOMAIN)

cert-renew:
	docker compose run --rm certbot renew
	docker compose exec nginx nginx -s reload

devices-list:
	docker compose exec openclaw-gateway node dist/index.js devices list

devices-approve:
	docker compose exec openclaw-gateway node dist/index.js devices approve $(ID)

.DEFAULT_GOAL := help
