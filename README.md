# docker-compose-cicd-stack

A small three-tier notes app (React + Django + PostgreSQL) used to practise containerising a stack with Docker Compose and automating its checks and image builds with GitHub Actions.

```
browser -> frontend (Nginx + React build) --/api, /healthz--> backend (Gunicorn + Django) -> db (PostgreSQL 16)
```

## Run locally
```bash
cp .env.example .env        # set DB_PASSWORD and DJANGO_SECRET_KEY to your own values
docker compose up --build
open http://localhost:8080  # Deploy Status page; API at /api/notes
docker compose ps           # all services should become "healthy"
```

Useful targets: `make help` (`up`, `down`, `logs`, `test`, `lint`, `smoke`, `backup`, `prod-up`).

## Design notes
- **Multi-stage frontend image**: Node builds and tests, final image is Nginx only.
- **Backend runs as a non-root user**; configuration via environment variables; migrations run once in a one-shot `migrate` service (so `backend` can be scaled).
- **Health checks everywhere**: Postgres `pg_isready`, backend `/healthz`, frontend `/healthz`; `depends_on: condition: service_healthy` orders startup.
- **Container hardening**: `read_only` root filesystems, `cap_drop: [ALL]` (only the capabilities Postgres/Nginx need are re-added), `no-new-privileges`, CPU/memory limits.
- **Reproducible backend build**: `backend/requirements.in` -> hashed `requirements.txt` (`pip-compile --generate-hashes --strip-extras`); the image installs with `--require-hashes`.
- **Persistence**: named volume `pgdata`.

## CI (`.github/workflows/ci.yml`)
| Job | What it does |
|---|---|
| `lint` | ruff, ESLint, hadolint (both Dockerfiles), ShellCheck |
| `dependency-audit` | `pip-audit` on the hashed lockfile, `npm audit` (production deps, high+) |
| `backend-test` | Django check, migration-drift check and tests against a PostgreSQL service container |
| `frontend-test` | `npm ci`, vitest, production build |
| `compose-smoke` | `docker compose up --wait`, then curls `/healthz` and `/api/notes` through the Nginx proxy and checks the `migrate` service exited 0 |
| `images` | Builds both images, scans with Trivy, and on `main` is configured to push to GHCR (provenance + SBOM) and sign with cosign |

Dependabot is configured for GitHub Actions, pip, npm and Docker.

> **Status:** the `images` job (Trivy scan, GHCR push, cosign signing) is written but has not yet completed a successful run, so image publishing and signing are not verified. Check the Actions tab for the current state of each job.

## Operations
```bash
make backup   # pg_dump -> tar.gz + sha256 + rotation, using ../server-ops-toolkit/scripts/backup.sh
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --wait   # registry images at a pinned TAG
```
`docker-compose.prod.yml` expects `REGISTRY` and `TAG` in `.env` and adds log rotation. It has not been deployed to a real server from this repository.

## Notes
- `scripts/backup-db.sh` expects the sibling repository `server-ops-toolkit` (override with `TOOLKIT_DIR`).
- The Django backend is duplicated in `django-gunicorn-nginx-deploy`; fixes need applying to both.
