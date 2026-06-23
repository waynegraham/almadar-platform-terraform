#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=deploy/lib/preflight-common.sh
source "${SCRIPT_DIR}/lib/preflight-common.sh"

ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.prod}"
IDENTIFIER_FILE="${IIIF_IDENTIFIER_FILE:-}"
IIIF_BASE_URL="${IIIF_BASE_URL:-}"
IIIF_VERSION="${IIIF_VERSION:-2}"
CONCURRENCY="${IIIF_WARM_CONCURRENCY:-3}"
CURL_TIMEOUT_SECONDS="${CURL_TIMEOUT_SECONDS:-30}"
PAUSE_SECONDS="${IIIF_WARM_PAUSE_SECONDS:-0}"
DRY_RUN=0

REQUEST_PATHS=(
  "/info.json"
  "/full/256,/0/default.jpg"
)

usage() {
  cat <<'EOF'
Usage:
  warm-iiif-cache.sh --identifiers identifiers.txt [options]

Options:
  --identifiers FILE   Newline-delimited IIIF source identifiers. Blank lines
                       and lines starting with # are ignored.
  --base-url URL       IIIF endpoint prefix before /2 or /3.
                       Example: https://iiif.example.org/iiif
  --iiif-version N     IIIF Image API version path segment. Default: 2.
  --concurrency N      Maximum simultaneous identifiers to verify. Default: 3.
  --timeout N          Per-request curl timeout in seconds. Default: 30.
  --pause N            Seconds to sleep after each identifier. Default: 0.
  --path PATH          Additional request path after the identifier. Can be
                       repeated. Default paths are kept unless --replace-paths
                       is provided first.
  --replace-paths      Clear default request paths before adding --path values.
  --dry-run            Print planned URLs without requesting them.
  -h, --help           Show this help.

Environment:
  ENV_FILE, IIIF_IDENTIFIER_FILE, IIIF_BASE_URL, IIIF_VERSION,
  IIIF_WARM_CONCURRENCY, IIIF_WARM_PAUSE_SECONDS, CURL_TIMEOUT_SECONDS.
EOF
}

die() {
  printf 'ERROR %s\n' "$*" >&2
  exit 1
}

positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

non_negative_number() {
  [[ "$1" =~ ^([0-9]+)(\.[0-9]+)?$ ]]
}

urlencode() {
  local input="$1"
  local output=""
  local i char hex

  LC_ALL=C
  for ((i = 0; i < ${#input}; i += 1)); do
    char="${input:i:1}"
    case "${char}" in
      [a-zA-Z0-9.~_-])
        output+="${char}"
        ;;
      *)
        printf -v hex '%%%02X' "'${char}"
        output+="${hex}"
        ;;
    esac
  done

  printf '%s' "${output}"
}

trim_line() {
  local line="$1"
  line="${line%$'\r'}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "${line}"
}

normalize_request_path() {
  local path="$1"
  if [[ "${path}" != /* ]]; then
    path="/${path}"
  fi
  printf '%s' "${path}"
}

infer_base_url() {
  if [[ -n "${IIIF_BASE_URL}" ]]; then
    printf '%s' "${IIIF_BASE_URL%/}"
    return
  fi

  if [[ -n "${IIIF_SITE_HOST:-}" ]]; then
    printf 'https://%s/iiif' "${IIIF_SITE_HOST}"
    return
  fi

  if [[ -n "${PUBLIC_SITE_HOST:-}" ]]; then
    printf 'https://%s/iiif' "${PUBLIC_SITE_HOST}"
    return
  fi

  return 1
}

request_url() {
  local identifier="$1"
  local request_path="$2"
  local encoded_identifier

  encoded_identifier="$(urlencode "${identifier}")"
  printf '%s/%s/%s%s' "${BASE_URL}" "${IIIF_VERSION}" "${encoded_identifier}" "${request_path}"
}

warm_identifier() {
  local identifier="$1"
  local request_path url status time_total size_download
  local failed=0

  for request_path in "${REQUEST_PATHS[@]}"; do
    url="$(request_url "${identifier}" "${request_path}")"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
      printf 'PLAN  %s %s\n' "${identifier}" "${url}"
      continue
    fi

    read -r status time_total size_download < <(
      curl -k -sS -o /dev/null \
        -w '%{http_code} %{time_total} %{size_download}' \
        --max-time "${CURL_TIMEOUT_SECONDS}" \
        "${url}" 2>/dev/null || printf '000 0 0'
    )

    case "${status}" in
      2??)
        printf 'OK    %s %s HTTP %s %ss %sB\n' "${identifier}" "${request_path}" "${status}" "${time_total}" "${size_download}"
        ;;
      *)
        printf 'FAIL  %s %s HTTP %s %ss %sB %s\n' "${identifier}" "${request_path}" "${status}" "${time_total}" "${size_download}" "${url}" >&2
        failed=1
        ;;
    esac
  done

  if [[ "${PAUSE_SECONDS}" != "0" ]]; then
    sleep "${PAUSE_SECONDS}"
  fi

  return "${failed}"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --identifiers)
      [[ "$#" -ge 2 ]] || die "--identifiers requires a file path"
      IDENTIFIER_FILE="$2"
      shift 2
      ;;
    --base-url)
      [[ "$#" -ge 2 ]] || die "--base-url requires a URL"
      IIIF_BASE_URL="$2"
      shift 2
      ;;
    --iiif-version)
      [[ "$#" -ge 2 ]] || die "--iiif-version requires a value"
      IIIF_VERSION="$2"
      shift 2
      ;;
    --concurrency)
      [[ "$#" -ge 2 ]] || die "--concurrency requires a value"
      CONCURRENCY="$2"
      shift 2
      ;;
    --timeout)
      [[ "$#" -ge 2 ]] || die "--timeout requires a value"
      CURL_TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --pause)
      [[ "$#" -ge 2 ]] || die "--pause requires a value"
      PAUSE_SECONDS="$2"
      shift 2
      ;;
    --replace-paths)
      REQUEST_PATHS=()
      shift
      ;;
    --path)
      [[ "$#" -ge 2 ]] || die "--path requires a request path"
      REQUEST_PATHS+=("$(normalize_request_path "$2")")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

if [[ -f "${ENV_FILE}" ]]; then
  load_env_file "${ENV_FILE}" || true
else
  warn "environment file not found: ${ENV_FILE}; continuing with shell environment only"
fi
require_command curl
command -v curl >/dev/null 2>&1 || die "curl is required"

[[ -n "${IDENTIFIER_FILE}" ]] || die "missing --identifiers or IIIF_IDENTIFIER_FILE"
[[ -f "${IDENTIFIER_FILE}" ]] || die "identifier file not found: ${IDENTIFIER_FILE}"
positive_integer "${CONCURRENCY}" || die "--concurrency must be a positive integer"
positive_integer "${CURL_TIMEOUT_SECONDS}" || die "--timeout must be a positive integer"
non_negative_number "${PAUSE_SECONDS}" || die "--pause must be a non-negative number"
positive_integer "${IIIF_VERSION}" || die "--iiif-version must be a positive integer"
[[ "${#REQUEST_PATHS[@]}" -gt 0 ]] || die "at least one request path is required"

BASE_URL="$(infer_base_url)" || die "set IIIF_BASE_URL, IIIF_SITE_HOST, or PUBLIC_SITE_HOST"
BASE_URL="${BASE_URL%/}"

info "Warming IIIF cache from ${IDENTIFIER_FILE}"
info "Base URL: ${BASE_URL}"
info "IIIF version: ${IIIF_VERSION}"
info "Concurrency: ${CONCURRENCY}"
info "Timeout: ${CURL_TIMEOUT_SECONDS}s"
info "Request paths: ${REQUEST_PATHS[*]}"

identifiers=()
while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line="$(trim_line "${raw_line}")"
  if [[ -z "${line}" || "${line}" == \#* ]]; then
    continue
  fi
  identifiers+=("${line}")
done < "${IDENTIFIER_FILE}"

[[ "${#identifiers[@]}" -gt 0 ]] || die "identifier file contains no identifiers"

info "Identifiers: ${#identifiers[@]}"

failures=0
pids=()

for identifier in "${identifiers[@]}"; do
  warm_identifier "${identifier}" &
  pids+=("$!")

  if [[ "${#pids[@]}" -ge "${CONCURRENCY}" ]]; then
    if ! wait "${pids[0]}"; then
      failures=$((failures + 1))
    fi
    pids=("${pids[@]:1}")
  fi
done

for pid in "${pids[@]}"; do
  if ! wait "${pid}"; then
    failures=$((failures + 1))
  fi
done

if [[ "${failures}" -gt 0 ]]; then
  printf '\nIIIF cache warm result: %d identifier(s) had at least one failed request\n' "${failures}" >&2
  exit 1
fi

printf '\nIIIF cache warm result: %d identifier(s) verified\n' "${#identifiers[@]}"
