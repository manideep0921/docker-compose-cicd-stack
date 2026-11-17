#!/usr/bin/env bash
# Dump the compose Postgres database and rotate dumps with server-ops-toolkit/backup.sh.
# Usage: scripts/backup-db.sh [BACKUP_DIR=./backups] [KEEP=7]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$ROOT/backups}"
KEEP="${2:-7}"
TOOLKIT="${TOOLKIT_DIR:-$ROOT/../server-ops-toolkit}"
stage="$(mktemp -d)"
cleanup() { rm -r -- "$stage"; }
trap cleanup EXIT

mkdir -p "$stage/notes-db" "$DEST"
docker compose -f "$ROOT/docker-compose.yml" exec -T db \
  pg_dump -U notes -d notes --clean --if-exists > "$stage/notes-db/notes.sql"
[[ -s "$stage/notes-db/notes.sql" ]] || { echo "empty dump, aborting" >&2; exit 1; }

if [[ -x "$TOOLKIT/scripts/backup.sh" ]]; then
  "$TOOLKIT/scripts/backup.sh" "$stage/notes-db" "$DEST" "$KEEP"   # tar.gz + sha256 + retention
else
  echo "server-ops-toolkit not found at $TOOLKIT; writing plain gzip dump" >&2
  gzip -c "$stage/notes-db/notes.sql" > "$DEST/notes-db-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"
fi
