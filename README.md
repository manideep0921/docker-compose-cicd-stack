# docker-compose-cicd-stack

Three-container stack with a GitHub Actions pipeline that tests and builds
the images.

```
browser -> frontend (Nginx + React build) --/api, /healthz--> backend (Gunicorn + Django) -> db (PostgreSQL 16)
```

## Run
```bash
cp .env.example .env        # set DB_PASSWORD and DJANGO_SECRET_KEY
docker compose up --build
open http://localhost:8080  # Deploy Status page; API at /api/notes
docker compose ps           # all services should become "healthy"
```

## Design notes
- **Multi-stage frontend image**: Node builds and tests, final image is Nginx only.
- **Backend runs as a non-root user**, config via environment variables, migrations on start.
- **Health checks everywhere**: Postgres `pg_isready`, backend `/healthz`, frontend `/healthz`;
  `depends_on: condition: service_healthy` orders startup.
- **Named volume** `pgdata` persists the database.

## CI (`.github/workflows/ci.yml`)
1. `backend-test`: Django check, migration drift check and tests against a PostgreSQL service container
2. `frontend-test`: `npm ci`, vitest, production build
3. `images`: Buildx builds both images with layer caching; on `main`, pushes to GHCR tagged with the commit SHA and `latest`
