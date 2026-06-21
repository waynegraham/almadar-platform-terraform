# AGENTS.md

## Purpose

This repository contains the complete platform infrastructure for the AlMadar Digital platform.

The goal of this repository is to ensure that all environments can be recreated from source control with minimal manual intervention.

This repository is the source of truth for:

* OCI infrastructure
* Kubernetes configuration
* Application deployment
* CI/CD
* Cloudflare configuration documentation
* Operational procedures
* Disaster recovery documentation

No infrastructure changes should exist solely in OCI, Cloudflare, GitHub, or any other external system without corresponding documentation and code in this repository.

---

# Core Principles

## Infrastructure as Code

All infrastructure must be defined in code.

Avoid:

* Manual OCI configuration
* Manual Kubernetes configuration
* Manual Cloudflare configuration
* One-off shell scripts

Preferred:

* Terraform
* Helm
* Kubernetes manifests
* GitHub Actions

If a component cannot be recreated from source control, it is considered undocumented technical debt.

---

## Reproducibility

A new engineer should be able to:

1. Clone the repository
2. Follow documentation
3. Recreate the entire platform

without institutional knowledge.

Documentation must assume no prior project familiarity.

---

## Environment Consistency

The local environment should mirror production as closely as practical.

Differences should be limited to infrastructure providers.

Example:

Local:

* MinIO

Production:

* OCI Object Storage

Applications should not require code changes between environments.

Configuration should be environment-driven.

---

## Simplicity Before Scale

The platform currently supports approximately:

* 1,000 collection objects
* IIIF image delivery
* Strapi CMS
* Next.js frontend

Do not introduce complexity for hypothetical future requirements.

Avoid introducing:

* Service meshes
* Multi-cluster deployments
* OpenSearch
* Distributed caching layers

unless there is a documented business requirement.

---

# Architecture Overview

## Applications

### Frontend

Technology:

* Next.js

Responsibilities:

* Public website
* Search interface
* Object discovery
* IIIF viewer integration

---

### CMS

Technology:

* Strapi

Responsibilities:

* Editorial content
* Collection metadata
* IIIF asset management
* Manifest configuration

---

### Image Server

Technology:

* Cantaloupe

Responsibilities:

* IIIF image delivery
* Tile generation
* Thumbnail generation

Images are stored in object storage and never on application containers.

---

## Data Storage

### PostgreSQL

Primary application database.

Contains:

* Strapi content
* Metadata
* Configuration

Managed through OCI PostgreSQL.

Application containers must remain stateless.

---

### Object Storage

IIIF Buckets:

* iiif-dev
* iiif-test
* iiif-prod

CMS Buckets:

* strapi-dev
* strapi-test
* strapi-prod

No image files should be stored on local container volumes.

---

## Kubernetes

Single OKE cluster.

Namespaces:

* dev
* test
* prod

Use namespaces before introducing additional clusters.

Additional clusters require documented justification.

---

# Repository Structure

```text
apps/
  frontend/
  strapi/

infrastructure/
  terraform/
  helm/
  k3d/

docs/

.github/
```

---

# Repository Workflows

## Local Development

Use the Makefile for common local tasks:

```bash
make bootstrap    # Install frontend and Strapi dependencies locally
make local-up     # Start Docker Compose services
make local-down   # Stop Docker Compose services
make test         # Run app test scripts where defined
make lint         # Run app lint scripts where defined
```

`make local-up` runs the Docker Compose stack: Next.js, Strapi, PostgreSQL,
MinIO, MinIO bucket initialization, and Cantaloupe.

Useful direct Compose commands:

```bash
docker compose ps
docker compose logs -f
docker compose config --quiet
docker compose up -d --force-recreate strapi
docker compose up -d --force-recreate minio-init
docker compose down
docker compose down -v
```

Only use `docker compose down -v` when local state can be discarded.

## App Commands

Frontend commands are run from `apps/frontend`:

```bash
npm install
npm run dev
npm run build
npm run lint
npm test
```

Strapi commands are run from `apps/strapi`:

```bash
npm install
npm run develop
npm run build
npm run migrate
npm test
```

The Strapi `test` script currently runs `npm run build`.

## Local Kubernetes

Use k3d when validating Kubernetes manifests or local cluster behavior.
Stop Docker Compose first because k3d binds the same local ports.

```bash
docker compose down
./infrastructure/k3d/bootstrap.sh
kubectl -n dev get pods
kubectl -n dev get svc
./infrastructure/k3d/delete.sh
```

## Helm Validation

Charts live under `infrastructure/helm/`. Lint chart defaults and
environment-specific values before changing deployable packaging:

```bash
helm lint infrastructure/helm/frontend
helm lint infrastructure/helm/frontend -f infrastructure/helm/frontend/values-dev.yaml
helm lint infrastructure/helm/strapi
helm lint infrastructure/helm/strapi -f infrastructure/helm/strapi/values-dev.yaml
helm lint infrastructure/helm/cantaloupe
helm lint infrastructure/helm/cantaloupe -f infrastructure/helm/cantaloupe/values-dev.yaml
```

Render templates locally when reviewing Kubernetes output:

```bash
helm template almadar-dev-frontend infrastructure/helm/frontend \
  -f infrastructure/helm/frontend/values-dev.yaml \
  --namespace dev
```

## Platform Validation Tests

Deployment validation tests live in `tests/validation` and use Playwright,
PostgreSQL, and S3-compatible object storage clients.

```bash
cd tests/validation
npm ci
npm test
npm run typecheck
```

Local defaults target Docker Compose and k3d ports. Production validation must
set explicit endpoint, database, object storage, and Strapi upload token
environment variables as documented in `tests/validation/README.md`.

## Terraform Workflow

Terraform environments live under `infrastructure/terraform/environments/`.
Each environment has its own README and `terraform.tfvars.example`.

```bash
terraform init
terraform plan
terraform apply
```

Do not commit `terraform.tfvars`, generated kubeconfig files, or Terraform
state files. Vault state contains secret payloads and must use an encrypted
remote backend for shared environments.

---

# Terraform Standards

## Rules

* Reusable modules preferred
* Avoid duplicated resources
* Variables must be documented
* Outputs must be documented

Directory structure:

```text
terraform/
  modules/
  environments/
```

---

## State Management

Terraform state must never be stored locally for shared environments.

Use remote state storage.

Document all backend configuration.

---

# Kubernetes Standards

## Helm

All deployable services must use Helm.

Avoid:

* Manual kubectl apply
* Environment-specific YAML duplication

Preferred:

* Shared charts
* Environment-specific values files

---

## Namespaces

Environment mapping:

* dev
* test
* prod

Do not deploy production workloads into non-production namespaces.

---

## Resources

Every deployment must define:

* requests
* limits

Never deploy workloads without resource constraints.

---

# Secrets Management

## Rules

Secrets must never be stored in:

* Git
* Terraform variables files
* Helm values files
* GitHub Actions workflows

Use:

* OCI Vault
* External Secrets Operator

All secret references should originate from OCI Vault.

---

# CI/CD Standards

## Source Control

Branch strategy:

```text
develop   -> dev
release/* -> test
main      -> prod
```

---

## Deployment Flow

Developer Push
→ GitHub Actions
→ OCI Runner
→ OCI Registry
→ Helm Upgrade
→ Kubernetes

---

## Testing Requirements

Every deployment must execute:

### Unit Tests

Application tests.

### Integration Tests

Application-to-service validation.

### Smoke Tests

Verify:

* Frontend
* Strapi
* Cantaloupe
* Database connectivity

before deployment is considered successful.

---

# Cloudflare Standards

Cloudflare responsibilities:

* DNS
* TLS
* WAF
* CDN

Cloudflare is not the source of truth.

All Cloudflare configuration must be documented in:

```text
docs/cloudflare.md
```

---

# Cost Management

The project is expected to operate under nonprofit budget constraints.

Before introducing new infrastructure:

Document:

* Monthly cost impact
* Operational complexity
* Business justification

Avoid introducing services that require dedicated operational expertise.

---

# Disaster Recovery

The platform is not considered production-ready until the following have been tested:

* Database restore
* Object storage recovery
* Kubernetes cluster rebuild
* Full environment recreation from source control

Disaster recovery procedures must be documented under:

```text
docs/runbooks/
```

---

# Architectural Decision Records

All major infrastructure decisions require an ADR.

Examples:

* Kubernetes adoption
* OCI service selection
* Storage architecture
* Search architecture

Store ADRs under:

```text
docs/adr/
```

No major platform decision should exist only in meeting notes or chat history.

---

# Definition of Done

Infrastructure work is not complete until:

* Code is committed
* Documentation is updated
* Tests pass
* Deployment succeeds
* Recovery procedure is documented

If a component cannot be recreated, monitored, and recovered, it is not finished.

---

# Guiding Philosophy

Favor boring technology.

Favor reproducibility.

Favor maintainability.

Optimize for the engineer who inherits this repository five years from now and has no access to the original implementation team.

The platform should be understandable, recoverable, and deployable without relying on institutional memory.
