#!/bin/sh
set -eu

NAMESPACE="${K8S_NAMESPACE:-dev}"

kubectl apply -f infrastructure/k3d/manifests/00-namespace.yaml
kubectl apply -f infrastructure/k3d/manifests
kubectl -n "${NAMESPACE}" get pods
kubectl -n "${NAMESPACE}" get svc
kubectl -n "${NAMESPACE}" rollout status statefulset/postgres
kubectl -n "${NAMESPACE}" rollout status deployment/minio
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/minio-init --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/strapi
kubectl -n "${NAMESPACE}" rollout status deployment/frontend
kubectl -n "${NAMESPACE}" rollout status deployment/cantaloupe

