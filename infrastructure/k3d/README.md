# k3d Local Kubernetes

This directory contains a local Kubernetes development environment for `almadar-platform`.

## Layout

```text
infrastructure/k3d/
  cluster.yaml.template       k3d cluster definition
  bootstrap.sh                create cluster, secrets, configmaps, workloads
  delete.sh                   delete the k3d cluster
  kubectl-commands.sh         reference kubectl commands
  manifests/                  Kubernetes resources for namespace dev
```

## Bootstrap

From the repository root:

```bash
cp .env.example .env
./infrastructure/k3d/bootstrap.sh
```

The script creates a k3d cluster named `almadar-dev`, applies the `dev` namespace, creates local Kubernetes secrets from `.env`, creates ConfigMaps, and deploys PostgreSQL, MinIO, Strapi, Next.js, and Cantaloupe.

## Verify

```bash
kubectl -n dev get pods
kubectl -n dev get svc
```

Expected public ports:

- Frontend: `http://localhost:3000`
- Strapi: `http://localhost:1337/admin`
- PostgreSQL: `localhost:5432`
- MinIO API: `http://localhost:9000`
- MinIO console: `http://localhost:9001`
- Cantaloupe: `http://localhost:8182`

## Delete

```bash
./infrastructure/k3d/delete.sh
```

