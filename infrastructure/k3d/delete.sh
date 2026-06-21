#!/bin/sh
set -eu

CLUSTER_NAME="${K3D_CLUSTER_NAME:-almadar-dev}"
k3d cluster delete "${CLUSTER_NAME}"

