#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
K3D_DIR="${ROOT_DIR}/infrastructure/k3d"
CLUSTER_NAME="${K3D_CLUSTER_NAME:-almadar-dev}"
NAMESPACE="${K8S_NAMESPACE:-dev}"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
CONFIG_FILE="/tmp/${CLUSTER_NAME}-k3d.yaml"

load_env() {
  if [ -f "${ENV_FILE}" ]; then
    set -a
    # shellcheck disable=SC1090
    . "${ENV_FILE}"
    set +a
  fi
}

default_env() {
  : "${POSTGRES_DB:=almadar}"
  : "${POSTGRES_USER:=almadar}"
  : "${POSTGRES_PASSWORD:=change-me-postgres-password}"
  : "${MINIO_ROOT_USER:=almadar}"
  : "${MINIO_ROOT_PASSWORD:=change-me-minio-password}"
  : "${MINIO_BUCKETS:=iiif-dev,strapi-dev}"
  : "${IIIF_BUCKET:=iiif-dev}"
  : "${S3_ACCESS_KEY_ID:=${MINIO_ROOT_USER}}"
  : "${S3_SECRET_ACCESS_KEY:=${MINIO_ROOT_PASSWORD}}"
  : "${S3_REGION:=us-east-1}"
  : "${S3_ENDPOINT:=http://minio:9000}"
  : "${S3_BUCKET:=strapi-dev}"
  : "${S3_ACL:=public-read}"
  : "${S3_SIGNED_URL_EXPIRES:=900}"
  : "${S3_FORCE_PATH_STYLE:=true}"
  : "${S3_ROOT_PATH:=uploads}"
  : "${S3_PUBLIC_BASE_URL:=http://localhost:9000/strapi-dev}"
  : "${STRAPI_UPLOADS_CSP_SRC:=http://localhost:9000}"
  : "${STRAPI_HOST:=0.0.0.0}"
  : "${STRAPI_PORT:=1337}"
  : "${APP_KEYS:=change-me-key-1,change-me-key-2}"
  : "${API_TOKEN_SALT:=change-me-api-token-salt}"
  : "${ADMIN_JWT_SECRET:=change-me-admin-jwt-secret}"
  : "${TRANSFER_TOKEN_SALT:=change-me-transfer-token-salt}"
  : "${JWT_SECRET:=change-me-jwt-secret}"
  : "${ENCRYPTION_KEY:=change-me-encryption-key}"
  : "${FRONTEND_PORT:=3000}"
  : "${NEXT_PUBLIC_STRAPI_URL:=http://localhost:1337}"
  : "${STRAPI_INTERNAL_URL:=http://strapi:1337}"
  : "${CANTALOUPE_S3_PREFIX:=}"
  : "${CANTALOUPE_S3_SUFFIX:=}"
}

create_cluster() {
  if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo "k3d cluster ${CLUSTER_NAME} already exists"
  else
    sed "s#__PROJECT_ROOT__#${ROOT_DIR}#g" "${K3D_DIR}/cluster.yaml.template" > "${CONFIG_FILE}"
    k3d cluster create --config "${CONFIG_FILE}"
  fi
}

apply_secrets() {
  kubectl apply -f "${K3D_DIR}/manifests/00-namespace.yaml"

  kubectl -n "${NAMESPACE}" create secret generic almadar-secrets \
    --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    --from-literal=MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD}" \
    --from-literal=S3_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}" \
    --from-literal=APP_KEYS="${APP_KEYS}" \
    --from-literal=API_TOKEN_SALT="${API_TOKEN_SALT}" \
    --from-literal=ADMIN_JWT_SECRET="${ADMIN_JWT_SECRET}" \
    --from-literal=TRANSFER_TOKEN_SALT="${TRANSFER_TOKEN_SALT}" \
    --from-literal=JWT_SECRET="${JWT_SECRET}" \
    --from-literal=ENCRYPTION_KEY="${ENCRYPTION_KEY}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

apply_config() {
  kubectl -n "${NAMESPACE}" create configmap almadar-config \
    --from-literal=POSTGRES_DB="${POSTGRES_DB}" \
    --from-literal=POSTGRES_USER="${POSTGRES_USER}" \
    --from-literal=MINIO_ROOT_USER="${MINIO_ROOT_USER}" \
    --from-literal=MINIO_BUCKETS="${MINIO_BUCKETS}" \
    --from-literal=IIIF_BUCKET="${IIIF_BUCKET}" \
    --from-literal=S3_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}" \
    --from-literal=S3_REGION="${S3_REGION}" \
    --from-literal=S3_ENDPOINT="${S3_ENDPOINT}" \
    --from-literal=S3_BUCKET="${S3_BUCKET}" \
    --from-literal=S3_ACL="${S3_ACL}" \
    --from-literal=S3_SIGNED_URL_EXPIRES="${S3_SIGNED_URL_EXPIRES}" \
    --from-literal=S3_FORCE_PATH_STYLE="${S3_FORCE_PATH_STYLE}" \
    --from-literal=S3_ROOT_PATH="${S3_ROOT_PATH}" \
    --from-literal=S3_PUBLIC_BASE_URL="${S3_PUBLIC_BASE_URL}" \
    --from-literal=STRAPI_UPLOADS_CSP_SRC="${STRAPI_UPLOADS_CSP_SRC}" \
    --from-literal=STRAPI_HOST="${STRAPI_HOST}" \
    --from-literal=STRAPI_PORT="${STRAPI_PORT}" \
    --from-literal=FRONTEND_PORT="${FRONTEND_PORT}" \
    --from-literal=NEXT_PUBLIC_STRAPI_URL="${NEXT_PUBLIC_STRAPI_URL}" \
    --from-literal=STRAPI_INTERNAL_URL="${STRAPI_INTERNAL_URL}" \
    --from-literal=CANTALOUPE_S3_PREFIX="${CANTALOUPE_S3_PREFIX}" \
    --from-literal=CANTALOUPE_S3_SUFFIX="${CANTALOUPE_S3_SUFFIX}" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl -n "${NAMESPACE}" create configmap cantaloupe-config \
    --from-file=cantaloupe.properties="${ROOT_DIR}/infrastructure/cantaloupe/cantaloupe.properties" \
    --dry-run=client -o yaml | kubectl apply -f -
}

deploy() {
  kubectl -n "${NAMESPACE}" delete job minio-init --ignore-not-found
  kubectl apply -f "${K3D_DIR}/manifests"

  kubectl -n "${NAMESPACE}" rollout status statefulset/postgres --timeout=180s
  kubectl -n "${NAMESPACE}" rollout status deployment/minio --timeout=180s
  kubectl -n "${NAMESPACE}" wait --for=condition=complete job/minio-init --timeout=180s
  kubectl -n "${NAMESPACE}" rollout status deployment/strapi --timeout=300s
  kubectl -n "${NAMESPACE}" rollout status deployment/frontend --timeout=300s
  kubectl -n "${NAMESPACE}" rollout status deployment/cantaloupe --timeout=240s

  kubectl -n "${NAMESPACE}" get pods -o wide
}

load_env
default_env
create_cluster
kubectl config use-context "k3d-${CLUSTER_NAME}"
apply_secrets
apply_config
deploy

