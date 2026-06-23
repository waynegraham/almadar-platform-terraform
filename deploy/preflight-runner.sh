#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=deploy/lib/preflight-common.sh
source "${SCRIPT_DIR}/lib/preflight-common.sh"

MIN_RUNNER_FREE_GB="${MIN_RUNNER_FREE_GB:-20}"

info "Running self-hosted runner preflight"

for command in docker git node npm ssh df awk; do
  require_command "${command}"
done

if docker info >/dev/null 2>&1; then
  pass "Docker daemon is reachable"
else
  fail "Docker daemon is not reachable; runner cannot build images"
fi

if docker compose version >/dev/null 2>&1; then
  pass "Docker Compose plugin is reachable"
else
  fail "Docker Compose plugin is not reachable"
fi

node_major="$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1 || true)"
if [[ "${node_major}" == "22" ]]; then
  pass "Node.js major version is 22"
else
  fail "Node.js major version is ${node_major:-unknown}; expected 22"
fi

available_gb="$(df -Pk . | awk 'NR == 2 { printf "%.0f", $4 / 1024 / 1024 }')"
if [[ "${available_gb}" -ge "${MIN_RUNNER_FREE_GB}" ]]; then
  pass "runner workspace filesystem has ${available_gb}GB free"
else
  fail "runner workspace filesystem has only ${available_gb}GB free; expected at least ${MIN_RUNNER_FREE_GB}GB"
fi

if [[ -n "${APP_VM_HOST:-}" ]]; then
  app_user="${APP_VM_USER:-opc}"
  if ssh -o BatchMode=yes -o ConnectTimeout=10 "${app_user}@${APP_VM_HOST}" 'docker version >/dev/null 2>&1' >/dev/null 2>&1; then
    pass "runner can SSH to app VM and reach Docker"
  else
    fail "runner cannot SSH to app VM or Docker is unavailable there"
  fi
else
  warn "APP_VM_HOST is not set; skipping SSH-to-app-VM check"
fi

if [[ -n "${CONTAINER_REGISTRY:-}" ]]; then
  if docker login "${CONTAINER_REGISTRY}" --username "${REGISTRY_USERNAME:-}" --password-stdin >/dev/null 2>&1 <<<"${REGISTRY_PASSWORD:-}"; then
    pass "container registry login succeeded: ${CONTAINER_REGISTRY}"
  else
    fail "container registry login failed: ${CONTAINER_REGISTRY}"
  fi
else
  warn "CONTAINER_REGISTRY is not set; skipping registry login check"
fi

for workflow in .github/workflows/deploy-prod.yml .github/workflows/deploy-dev.yml; do
  if [[ -f "${workflow}" ]]; then
    pass "workflow exists: ${workflow}"
  else
    fail "workflow missing: ${workflow}"
  fi
done

if grep -R "runs-on: \\[self-hosted, oci, almadar, prod\\]" .github/workflows/deploy-prod.yml >/dev/null 2>&1; then
  pass "production workflow targets the expected self-hosted runner labels"
else
  fail "production workflow does not target expected self-hosted runner labels"
fi

finish_preflight
