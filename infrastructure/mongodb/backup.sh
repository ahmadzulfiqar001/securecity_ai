#!/usr/bin/env bash
#
# SecureCity AI — MongoDB backup script (ai_engine/cv_engine ML data only).
# See backend/docs/mongodb-schema.md for the retention/restore policy this
# implements.
#
# Usage:
#   ./backup.sh
#
# Env vars:
#   MONGO_URL      — full connection string. If not set, it's built from
#                    MONGO_ROOT_USER/MONGO_ROOT_PASSWORD/MONGO_DB, and
#                    MONGO_ROOT_PASSWORD is then REQUIRED (no insecure
#                    default — see docker-compose.yml's REDIS_PASSWORD/
#                    MONGO_ROOT_PASSWORD for the same policy).
#   BACKUP_DEST    — directory to write archives to (default: ./backups/mongodb)
#   RETENTION_DAYS — how many daily archives to keep locally (default: 14)
#
# Designed to be invoked by cron or a Kubernetes CronJob: no interactive
# input, exits non-zero on failure so the scheduler can alert.

set -euo pipefail

MONGO_URL="${MONGO_URL:-mongodb://${MONGO_ROOT_USER:-mongoadmin}:${MONGO_ROOT_PASSWORD:?MONGO_ROOT_PASSWORD is required when MONGO_URL is not set}@localhost:27017/${MONGO_DB:-securecity_ml}?authSource=admin}"
BACKUP_DEST="${BACKUP_DEST:-./backups/mongodb}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive_path="${BACKUP_DEST}/securecity_ml_${timestamp}.archive.gz"

mkdir -p "${BACKUP_DEST}"

echo "[backup.sh] Starting mongodump -> ${archive_path}"
mongodump \
  --uri="${MONGO_URL}" \
  --archive="${archive_path}" \
  --gzip

echo "[backup.sh] Backup complete: $(du -h "${archive_path}" | cut -f1)"

echo "[backup.sh] Pruning archives older than ${RETENTION_DAYS} days in ${BACKUP_DEST}"
find "${BACKUP_DEST}" -maxdepth 1 -name "securecity_ml_*.archive.gz" -mtime "+${RETENTION_DAYS}" -print -delete

echo "[backup.sh] Done."

# ---------------------------------------------------------------------------
# Restore (for reference — not run by this script):
#
#   mongorestore --uri="$MONGO_URL" --archive=<path-to-archive> --gzip --drop
#
# --drop replaces the target collections wholesale rather than merging with
# live data — appropriate for restoring operational ML data after an
# incident, not for partial recovery.
# ---------------------------------------------------------------------------
