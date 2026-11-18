FROM python:3.15-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Packages are intentionally unpinned: pinned Debian versions disappear from the
# mirrors on security updates and would break rebuilds. The base image tag is the pin.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# requirements.txt is a hashed lockfile (regenerate from requirements.in); any mismatch fails the build
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

COPY . .
RUN DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput \
    && useradd --system --uid 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8000/healthz || exit 1

# Migrations are NOT run here: compose runs them once via the one-shot "migrate" service.
CMD ["sh", "-c", "exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers ${GUNICORN_WORKERS:-3} --worker-tmp-dir /dev/shm --no-control-socket --access-logfile -"]
