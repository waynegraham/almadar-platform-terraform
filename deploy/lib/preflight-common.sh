#!/usr/bin/env bash

set -uo pipefail

PREFLIGHT_FAILURES=0
PREFLIGHT_WARNINGS=0

info() {
  printf 'INFO  %s\n' "$*"
}

pass() {
  printf 'PASS  %s\n' "$*"
}

warn() {
  PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
  printf 'WARN  %s\n' "$*" >&2
}

fail() {
  PREFLIGHT_FAILURES=$((PREFLIGHT_FAILURES + 1))
  printf 'FAIL  %s\n' "$*" >&2
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command available: $1"
  else
    fail "missing required command: $1"
  fi
}

require_file() {
  if [[ -f "$1" ]]; then
    pass "file exists: $1"
  else
    fail "missing file: $1"
  fi
}

load_env_file() {
  local env_file="$1"

  if [[ ! -f "${env_file}" ]]; then
    fail "environment file not found: ${env_file}"
    return 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "${env_file}"
  set +a
}

require_env() {
  local name="$1"
  local value="${!name:-}"

  if [[ -n "${value}" ]]; then
    pass "environment value set: ${name}"
  else
    fail "missing required environment value: ${name}"
  fi
}

warn_placeholder_env() {
  local name="$1"
  local value="${!name:-}"

  if [[ -z "${value}" ]]; then
    return 0
  fi

  if [[ "${value}" == *replace* || "${value}" == *example.org* || "${value}" == *REPLACE_WITH* ]]; then
    fail "environment value still looks like a placeholder: ${name}"
  fi
}

http_status() {
  local url="$1"
  shift

  curl -k -sS -o /dev/null -w '%{http_code}' --max-time "${CURL_TIMEOUT_SECONDS:-10}" "$@" "${url}" 2>/dev/null || true
}

finish_preflight() {
  printf '\nPreflight result: %d failure(s), %d warning(s)\n' "${PREFLIGHT_FAILURES}" "${PREFLIGHT_WARNINGS}"

  if [[ "${PREFLIGHT_FAILURES}" -gt 0 ]]; then
    return 1
  fi

  return 0
}
