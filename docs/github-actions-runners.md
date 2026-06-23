# GitHub Actions OCI Runner Deployment

This document describes the self-hosted GitHub Actions runner used by the
simplified VM + Docker Compose launch path.

It does not use Kubernetes, Helm, Actions Runner Controller, or External
Secrets Operator.

## Runner Labels

Register the runner with these labels:

```text
self-hosted
oci
almadar
prod
```

The deployment workflows target all labels:

```yaml
runs-on: [self-hosted, oci, almadar, prod]
```

## Workflows

Deployment workflows:

```text
.github/workflows/deploy-dev.yml
.github/workflows/deploy-prod.yml
```

Both workflows:

- run on the OCI self-hosted runner,
- build frontend and Strapi Docker images,
- push images to GHCR or OCIR,
- SSH from the runner VM to the app VM,
- copy the `deploy/` Compose bundle to the app VM,
- update image tags in the remote environment file,
- run:

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

Production uses the GitHub Environment named `production`. Configure required
reviewers on that environment so production deployment waits for approval.

## GitHub Environments

Create these environments:

```text
development
production
```

Recommended settings:

- `development`: no required reviewers, environment-scoped dev VM values.
- `production`: required reviewers enabled, environment-scoped production VM
  values.

## Required Variables

Configure these as repository, organization, or environment variables.
Environment variables are preferred when dev and prod use different app VMs.

```text
CONTAINER_REGISTRY
CONTAINER_NAMESPACE
APP_VM_USER
APP_DEPLOY_PATH
APP_ENV_FILE
```

Examples for GHCR:

```text
CONTAINER_REGISTRY=ghcr.io
CONTAINER_NAMESPACE=waynegraham
APP_VM_USER=opc
APP_DEPLOY_PATH=/opt/almadar/deploy
APP_ENV_FILE=.env.prod
```

Examples for OCIR:

```text
CONTAINER_REGISTRY=me-riyadh-1.ocir.io
CONTAINER_NAMESPACE=<oci-tenancy-namespace>
APP_VM_USER=opc
APP_DEPLOY_PATH=/opt/almadar/deploy
APP_ENV_FILE=.env.prod
```

For `deploy-dev`, set `APP_ENV_FILE=.env.dev` if dev uses a separate
environment file on the app VM.

## Required Secrets

Configure these as environment secrets where possible:

```text
REGISTRY_USERNAME
REGISTRY_PASSWORD
APP_VM_HOST
APP_VM_SSH_PRIVATE_KEY
```

Registry notes:

- For GHCR, use a GitHub user or machine user for `REGISTRY_USERNAME` and a PAT
  with package write/read access for `REGISTRY_PASSWORD`.
- For OCIR, use the OCI registry username format required by the tenancy and an
  auth token for `REGISTRY_PASSWORD`.
- The app VM also logs into the same registry over SSH before pulling images.

SSH notes:

- `APP_VM_HOST` is the app VM DNS name or public/private IP reachable from the
  runner VM.
- `APP_VM_SSH_PRIVATE_KEY` must match a public key installed for `APP_VM_USER`
  on the app VM.
- Restrict SSH access at the OCI NSG/security-list level to the runner VM or
  approved admin addresses.

## Runner VM Setup

Install on the runner VM:

- GitHub Actions runner service,
- Docker Engine,
- Docker Compose plugin,
- Node.js 22,
- Git,
- SSH client.

The runner user must be able to run Docker commands. On Oracle Linux this
usually means adding the runner user to the Docker group after Docker is
installed, then restarting the runner service.

Register the runner at the repository or organization level with the required
labels. Keep the runner dedicated to this deployment path unless there is a
documented reason to share it.

## App VM Setup

Before the first deployment:

1. Install Docker Engine and Docker Compose plugin.
2. Create the deploy directory, for example `/opt/almadar/deploy`.
3. Create the environment file, for example `/opt/almadar/deploy/.env.prod`,
   from `deploy/.env.prod.example`.
4. Fill in PostgreSQL, Object Storage, Strapi, Cantaloupe, and hostname values.
5. Mount the VM data volume so Docker data and `CANTALOUPE_CACHE_PATH` have
   enough space.

The workflows copy `compose.prod.yml`, `Caddyfile`, `deploy.sh`, `backup.sh`,
and `README.md` to the app VM. They do not overwrite `.env.prod` or `.env.dev`.

## Operational Notes

- Keep production approval in GitHub Environments, not in workflow shell logic.
- Do not store production environment files in Git.
- Do not add Kubernetes, Helm, Actions Runner Controller, or External Secrets
  Operator to this deployment path.
