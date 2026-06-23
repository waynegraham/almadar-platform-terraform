#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.prod}"
COMPOSE_FILE="${COMPOSE_FILE:-${SCRIPT_DIR}/compose.prod.yml}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy deploy/.env.prod.example to ${ENV_FILE} and fill in production values." >&2
  exit 1
fi

cd "${SCRIPT_DIR}"

cache_path="$(grep -E '^CANTALOUPE_CACHE_PATH=' "${ENV_FILE}" | tail -1 | cut -d= -f2- || true)"
cache_path="${cache_path:-/var/lib/almadar/cantaloupe-cache}"
mkdir -p "${cache_path}"

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --remove-orphans

docker image prune -f

echo "Waiting for services to report healthy..."
for service in strapi cantaloupe frontend proxy; do
  container="almadar-${service}"
  if [[ "${service}" == "proxy" ]]; then
    container="almadar-proxy"
  fi

  for attempt in $(seq 1 40); do
    status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container}" 2>/dev/null || true)"
    if [[ "${status}" == "healthy" || "${status}" == "running" ]]; then
      echo "${container}: ${status}"
      break
    fi
    if [[ "${attempt}" == "40" ]]; then
      echo "${container} did not become healthy. Current status: ${status}" >&2
      docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
      exit 1
    fi
    sleep 3
  done
done

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
