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
- **Backend runs as a non-root user**, config via environment variables, migrations run once by a one-shot `migrate` service (safe to scale `backend`).
- **Health checks everywhere**: Postgres `pg_isready`, backend `/healthz`, frontend `/healthz`;
  `depends_on: condition: service_healthy` orders startup.
- **Hardened containers**: `read_only` root filesystems, `cap_drop: [ALL]` (only the caps Postgres/Nginx need
  are re-added), `no-new-privileges`, CPU/memory limits.
- **Reproducible backend build**: `backend/requirements.in` -> hashed `requirements.txt`
  (`pip-compile --generate-hashes --strip-extras`); the image installs with `--require-hashes`.
- **Named volume** `pgdata` persists the database.

## CI (`.github/workflows/ci.yml`)
1. `backend-test`: Django check, migration drift check and tests against a PostgreSQL service container
2. `frontend-test`: `npm ci`, vitest, production build
3. `images`: Buildx builds both images with layer caching; on `main`, pushes to GHCR tagged with the commit SHA and `latest`

## Operations
```bash
make up / down / logs / smoke      # see `make help`
make backup                        # pg_dump -> tar.gz + sha256 + rotation via ../server-ops-toolkit/scripts/backup.sh
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --wait   # registry images, pinned TAG
```

## CI additions
- `lint`: ruff, ESLint, hadolint (both Dockerfiles), shellcheck
- `dependency-audit`: `pip-audit` on the hashed lockfile, `npm audit`
- `compose-smoke`: `docker compose up --wait`, then curls `/healthz` and `/api/notes` through the Nginx proxy
- `images`: Trivy scan before push; on `main` pushes with provenance + SBOM attestations and keyless cosign signature
- Dependabot: Actions, pip, npm, Docker

> The Django backend here is duplicated in `../django-gunicorn-nginx-deploy`; keep fixes in sync.
