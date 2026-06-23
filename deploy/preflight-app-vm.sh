#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=deploy/lib/preflight-common.sh
source "${SCRIPT_DIR}/lib/preflight-common.sh"

ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.prod}"
COMPOSE_FILE="${COMPOSE_FILE:-${SCRIPT_DIR}/compose.prod.yml}"
MIN_CACHE_FREE_GB="${MIN_CACHE_FREE_GB:-50}"
MIN_DOCKER_FREE_GB="${MIN_DOCKER_FREE_GB:-20}"

gb_available_for_path() {
  local path="$1"
  df -Pk "${path}" | awk 'NR == 2 { printf "%.0f", $4 / 1024 / 1024 }'
}

check_free_gb() {
  local label="$1"
  local path="$2"
  local minimum_gb="$3"

  if [[ ! -e "${path}" ]]; then
    fail "${label} path does not exist: ${path}"
    return
  fi

  local available_gb
  available_gb="$(gb_available_for_path "${path}")"

  if [[ "${available_gb}" -ge "${minimum_gb}" ]]; then
    pass "${label} has ${available_gb}GB free at ${path}"
  else
    fail "${label} has only ${available_gb}GB free at ${path}; expected at least ${minimum_gb}GB"
  fi
}

check_mount() {
  local path="$1"

  if command -v findmnt >/dev/null 2>&1; then
    if findmnt -T "${path}" >/dev/null 2>&1; then
      pass "mount detected for ${path}: $(findmnt -n -T "${path}" -o TARGET,SOURCE,FSTYPE)"
    else
      fail "no mount detected for ${path}"
    fi
  else
    warn "findmnt is unavailable; cannot verify mount for ${path}"
  fi
}

info "Running app VM preflight with ${ENV_FILE}"

require_file "${ENV_FILE}"
require_file "${COMPOSE_FILE}"
load_env_file "${ENV_FILE}" || true

for command in docker curl df awk; do
  require_command "${command}"
done

for name in \
  PUBLIC_SITE_HOST \
  FRONTEND_IMAGE \
  FRONTEND_TAG \
  STRAPI_IMAGE \
  STRAPI_TAG \
  DATABASE_HOST \
  DATABASE_NAME \
  DATABASE_USERNAME \
  DATABASE_PASSWORD \
  S3_ENDPOINT \
  S3_BUCKET \
  S3_ACCESS_KEY_ID \
  S3_SECRET_ACCESS_KEY \
  CANTALOUPE_S3SOURCE_ENDPOINT \
  CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_BUCKET_NAME \
  CANTALOUPE_S3SOURCE_ACCESS_KEY_ID \
  CANTALOUPE_S3SOURCE_SECRET_KEY; do
  require_env "${name}"
  warn_placeholder_env "${name}"
done

if [[ "${DATABASE_SSL:-}" == "true" ]]; then
  pass "DATABASE_SSL=true"
else
  fail "DATABASE_SSL should be true in production"
fi

if [[ "${DATABASE_SSL_REJECT_UNAUTHORIZED:-}" == "false" ]]; then
  warn "DATABASE_SSL_REJECT_UNAUTHORIZED=false; document the exception or install the CA and enable verification"
fi

if docker info >/dev/null 2>&1; then
  pass "Docker daemon is reachable"
else
  fail "Docker daemon is not reachable"
fi

if docker compose version >/dev/null 2>&1; then
  pass "Docker Compose plugin is reachable"
else
  fail "Docker Compose plugin is not reachable"
fi

ALMADAR_ENV_FILE="${ENV_FILE}" docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" config --quiet \
  && pass "production Compose config is valid" \
  || fail "production Compose config is invalid"

cache_path="${CANTALOUPE_CACHE_PATH:-/var/lib/almadar/cantaloupe-cache}"
mkdir -p "${cache_path}" 2>/dev/null || true

if [[ -d "${cache_path}" && -w "${cache_path}" ]]; then
  pass "Cantaloupe cache path is writable: ${cache_path}"
else
  fail "Cantaloupe cache path is not writable: ${cache_path}"
fi

check_mount "${cache_path}"
check_free_gb "Cantaloupe cache filesystem" "${cache_path}" "${MIN_CACHE_FREE_GB}"

docker_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
if [[ -n "${docker_root}" ]]; then
  pass "Docker root directory: ${docker_root}"
  check_free_gb "Docker root filesystem" "${docker_root}" "${MIN_DOCKER_FREE_GB}"
else
  fail "could not determine Docker root directory"
fi

if [[ -f /etc/docker/daemon.json ]] && grep -q '"max-size"' /etc/docker/daemon.json; then
  pass "Docker log rotation appears configured in /etc/docker/daemon.json"
else
  warn "Docker log rotation not detected; configure json-file max-size/max-file before launch"
fi

if docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps >/dev/null 2>&1; then
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
else
  warn "Compose stack is not running or cannot be inspected"
fi

for container in almadar-proxy almadar-frontend almadar-strapi almadar-cantaloupe; do
  status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container}" 2>/dev/null || true)"
  if [[ "${status}" == "healthy" || "${status}" == "running" ]]; then
    pass "${container} status is ${status}"
  else
    fail "${container} status is ${status:-missing}"
  fi
done

public_status="$(http_status "http://127.0.0.1/healthz" -H "Host: ${PUBLIC_SITE_HOST:-localhost}")"
if [[ "${public_status}" == "200" ]]; then
  pass "local proxy health route responds for PUBLIC_SITE_HOST"
else
  fail "local proxy health route returned ${public_status:-no response} for PUBLIC_SITE_HOST"
fi

if [[ -n "${CMS_SITE_HOST:-}" ]]; then
  cms_status="$(http_status "http://127.0.0.1/healthz" -H "Host: ${CMS_SITE_HOST}")"
  if [[ "${cms_status}" == "200" ]]; then
    pass "local proxy health route responds for CMS_SITE_HOST"
  else
    fail "local proxy health route returned ${cms_status:-no response} for CMS_SITE_HOST"
  fi
fi

if [[ -n "${IIIF_SITE_HOST:-}" ]]; then
  iiif_status="$(http_status "http://127.0.0.1/healthz" -H "Host: ${IIIF_SITE_HOST}")"
  if [[ "${iiif_status}" == "200" ]]; then
    pass "local proxy health route responds for IIIF_SITE_HOST"
  else
    fail "local proxy health route returned ${iiif_status:-no response} for IIIF_SITE_HOST"
  fi
fi

if command -v oci >/dev/null 2>&1 && [[ -n "${BACKUP_BUCKET:-}" ]]; then
  namespace="$(oci os ns get --query 'data' --raw-output 2>/dev/null || true)"
  if [[ -n "${namespace}" ]] && oci os bucket get --namespace-name "${namespace}" --bucket-name "${BACKUP_BUCKET}" >/dev/null 2>&1; then
    pass "OCI backups bucket is reachable: ${BACKUP_BUCKET}"
  else
    fail "OCI backups bucket is not reachable: ${BACKUP_BUCKET}"
  fi
else
  warn "OCI CLI or BACKUP_BUCKET not configured; backup upload cannot be verified"
fi

finish_preflight
