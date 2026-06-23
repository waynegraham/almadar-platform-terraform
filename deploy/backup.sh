#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.prod}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/almadar}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_ROOT}/${STAMP}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy deploy/.env.prod.example to ${ENV_FILE} and fill in production values." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

mkdir -p "${BACKUP_DIR}"

echo "Writing Compose configuration backup to ${BACKUP_DIR}"
cp "${SCRIPT_DIR}/compose.prod.yml" "${BACKUP_DIR}/compose.prod.yml"
cp "${SCRIPT_DIR}/Caddyfile" "${BACKUP_DIR}/Caddyfile"
cp "${ENV_FILE}" "${BACKUP_DIR}/env.prod"

if command -v docker >/dev/null 2>&1; then
  docker ps --format '{{.Names}} {{.Image}} {{.Status}}' > "${BACKUP_DIR}/containers.txt"
  docker volume ls > "${BACKUP_DIR}/docker-volumes.txt"
fi

tar -C "${BACKUP_ROOT}" -czf "${BACKUP_ROOT}/almadar-compose-${STAMP}.tar.gz" "${STAMP}"
rm -rf "${BACKUP_DIR}"

echo "Created ${BACKUP_ROOT}/almadar-compose-${STAMP}.tar.gz"

if command -v oci >/dev/null 2>&1 && [[ -n "${BACKUP_BUCKET:-}" ]]; then
  namespace="$(oci os ns get --query 'data' --raw-output)"
  object_name="${BACKUP_PREFIX:-vm-compose}/almadar-compose-${STAMP}.tar.gz"
  oci os object put \
    --namespace-name "${namespace}" \
    --bucket-name "${BACKUP_BUCKET}" \
    --name "${object_name}" \
    --file "${BACKUP_ROOT}/almadar-compose-${STAMP}.tar.gz" \
    --force
  echo "Uploaded backup to oci://${BACKUP_BUCKET}/${object_name}"
else
  echo "OCI CLI or BACKUP_BUCKET not configured; backup remains local."
fi

find "${BACKUP_ROOT}" -name 'almadar-compose-*.tar.gz' -type f -mtime "+${BACKUP_RETENTION_DAYS:-30}" -delete

