# ADR-004: GitHub Actions Runner Controller

Date: 2026-06-21

Status: Deferred for August 1, 2026 launch by ADR-007

## Context

CI/CD must build images, push them to OCIR, run migrations, deploy Helm charts,
and validate the deployed platform. The deployment path needs access to OCI,
OKE, OCIR, and private network resources. The project also requires GitHub
organization support and ephemeral runners so build state does not persist
between jobs.

Using GitHub-hosted runners for all deployment work would require exposing more
cloud access to external runners and may not match the desired OCI-hosted
execution model.

## Decision

Deploy GitHub Actions Runner Controller (ARC) into OKE and use ARC runner scale
sets for OCI-hosted, ephemeral, autoscaled GitHub Actions runners.

Use an organization-scoped runner scale set named `almadar-oci-oke`. Store ARC
GitHub App credentials in OCI Vault and synchronize them into Kubernetes through
External Secrets.

## Consequences

Positive consequences:

- CI/CD jobs execute on OCI-hosted runners close to the target infrastructure.
- Ephemeral runners reduce cross-job contamination and secret persistence risk.
- Autoscaling avoids paying for always-on runner capacity when there are no
  queued jobs.
- Organization-level runners can serve multiple repositories if the platform
  expands.
- Runner deployment is documented and reproducible from this repository.

Negative consequences:

- CI/CD availability now depends on OKE availability.
- ARC adds Kubernetes resources and operational responsibility.
- GitHub App credentials become part of the platform secret lifecycle.
- Bootstrap and disaster recovery must restore runners before normal
  self-hosted CI/CD can resume.

## Alternatives Considered

- GitHub-hosted runners: simpler to operate, but less aligned with OCI-hosted
  execution and private infrastructure access.
- Static self-hosted VM runners: straightforward, but long-lived runners retain
  more state and require patching, scaling, and cleanup.
- Manual deployments from engineer machines: rejected because deployments must
  be reproducible, auditable, and source-controlled.
- A separate CI platform: unnecessary additional operational surface for the
  current team and platform scale.
