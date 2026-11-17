.PHONY: help up down logs ps test lint smoke backup prod-up
COMPOSE ?= docker compose

help:        ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/'
up:          ## build and start the stack
	$(COMPOSE) up --build -d --wait
down:        ## stop the stack (keeps the database volume)
	$(COMPOSE) down
logs:        ## tail logs
	$(COMPOSE) logs -f --tail=100
ps:          ## service status
	$(COMPOSE) ps
test:        ## backend + frontend tests
	cd backend && python manage.py test
	cd frontend && npm test
lint:        ## ruff, eslint, hadolint, shellcheck
	cd backend && ruff check .
	cd frontend && npm run lint
	hadolint backend/Dockerfile frontend/Dockerfile
	shellcheck scripts/*.sh
smoke:       ## start stack and hit the API
	$(COMPOSE) up --build -d --wait
	curl -fsS http://localhost:$${HTTP_PORT:-8080}/api/notes
backup:      ## dump Postgres to ./backups (rotation via server-ops-toolkit)
	./scripts/backup-db.sh
prod-up:     ## run registry images with the prod override
	$(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml up -d --wait
