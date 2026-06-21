#!/bin/sh
set -eu

: "${MINIO_ENDPOINT:=http://minio:9000}"
: "${MINIO_ROOT_USER:?MINIO_ROOT_USER is required}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD is required}"
: "${MINIO_BUCKETS:=iiif-dev,strapi-dev}"

mc alias set local "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

old_ifs="${IFS}"
IFS=","
for bucket in ${MINIO_BUCKETS}; do
  if [ -n "${bucket}" ]; then
    mc mb --ignore-existing "local/${bucket}"
    mc anonymous set download "local/${bucket}"
  fi
done
IFS="${old_ifs}"

mc ls local
