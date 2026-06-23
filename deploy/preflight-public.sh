#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=deploy/lib/preflight-common.sh
source "${SCRIPT_DIR}/lib/preflight-common.sh"

ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.prod}"

check_public_url() {
  local label="$1"
  local url="$2"
  local status

  status="$(http_status "${url}")"

  case "${status}" in
    200|204|301|302|307|308|401|403)
      pass "${label} responds with HTTP ${status}: ${url}"
      ;;
    *)
      fail "${label} returned HTTP ${status:-no response}: ${url}"
      ;;
  esac
}

check_cloudflare_headers() {
  local label="$1"
  local url="$2"
  local headers

  headers="$(curl -k -sS -I --max-time "${CURL_TIMEOUT_SECONDS:-10}" "${url}" 2>/dev/null || true)"

  if printf '%s\n' "${headers}" | grep -iq '^cf-ray:'; then
    pass "${label} appears proxied through Cloudflare"
  else
    warn "${label} response did not include cf-ray; confirm Cloudflare proxy is enabled"
  fi
}

check_origin_bypass() {
  local host="$1"
  local ip="$2"
  local status

  status="$(http_status "http://${ip}/" -H "Host: ${host}")"

  case "${status}" in
    000|"")
      pass "direct HTTP origin did not respond for ${host}"
      ;;
    403|404|421|525|526)
      pass "direct HTTP origin is not serving normal traffic for ${host} (HTTP ${status})"
      ;;
    *)
      fail "direct HTTP origin responded with HTTP ${status} for ${host}; origin may bypass Cloudflare"
      ;;
  esac
}

info "Running public edge preflight with ${ENV_FILE}"

require_file "${ENV_FILE}"
load_env_file "${ENV_FILE}" || true
require_command curl

require_env PUBLIC_SITE_HOST
warn_placeholder_env PUBLIC_SITE_HOST

public_url="https://${PUBLIC_SITE_HOST:-}"
check_public_url "public frontend" "${public_url}/"
check_cloudflare_headers "public frontend" "${public_url}/"

if [[ -n "${CMS_SITE_HOST:-}" ]]; then
  warn_placeholder_env CMS_SITE_HOST
  check_public_url "CMS admin" "https://${CMS_SITE_HOST}/admin"
  check_cloudflare_headers "CMS admin" "https://${CMS_SITE_HOST}/admin"
else
  check_public_url "CMS path" "${public_url}/cms/admin"
fi

if [[ -n "${IIIF_SITE_HOST:-}" ]]; then
  warn_placeholder_env IIIF_SITE_HOST
  check_public_url "IIIF root" "https://${IIIF_SITE_HOST}/"
  check_cloudflare_headers "IIIF root" "https://${IIIF_SITE_HOST}/"
fi

if [[ -n "${KNOWN_IIIF_IDENTIFIER:-}" ]]; then
  encoded_identifier="${KNOWN_IIIF_IDENTIFIER//\//%2F}"
  check_public_url "known IIIF info.json" "${public_url}/iiif/2/${encoded_identifier}/info.json"
else
  warn "KNOWN_IIIF_IDENTIFIER is not set; skipping end-to-end IIIF object check"
fi

if [[ -n "${APP_VM_PUBLIC_IP:-}" ]]; then
  check_origin_bypass "${PUBLIC_SITE_HOST}" "${APP_VM_PUBLIC_IP}"
  if [[ -n "${CMS_SITE_HOST:-}" ]]; then
    check_origin_bypass "${CMS_SITE_HOST}" "${APP_VM_PUBLIC_IP}"
  fi
  if [[ -n "${IIIF_SITE_HOST:-}" ]]; then
    check_origin_bypass "${IIIF_SITE_HOST}" "${APP_VM_PUBLIC_IP}"
  fi
else
  warn "APP_VM_PUBLIC_IP is not set; skipping direct-origin bypass checks"
fi

finish_preflight
