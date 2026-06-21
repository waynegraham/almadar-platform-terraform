# ADR-001: Kubernetes on OCI

Date: 2026-06-21

Status: Accepted

## Context

The AlMadar platform runs a Next.js frontend, Strapi CMS, Cantaloupe IIIF image
server, PostgreSQL, and object storage integrations. The platform must be
reproducible from source control and must support `dev`, `test`, and `prod`
environments with minimal manual infrastructure changes.

OCI is the selected cloud provider for production infrastructure. The platform
needs a deployment target that can run stateless application containers, expose
HTTP services through an OCI Load Balancer, integrate with OCI networking and
secrets, and support repeatable deployment through Helm and GitHub Actions.

## Decision

Run application workloads on Oracle Kubernetes Engine (OKE).

Use Terraform to provision OKE infrastructure and Helm charts to deploy
application services. Kubernetes manifests and Helm values in this repository
are the source of truth for workload configuration.

## Consequences

Positive consequences:

- Application deployments are portable across local k3d and production OKE.
- Helm provides a repeatable deployment interface for frontend, Strapi, and
  Cantaloupe.
- OKE integrates with OCI networking, load balancing, and IAM.
- Stateless application containers can be rebuilt and redeployed from source
  control.
- GitHub Actions can deploy into Kubernetes using the same operational model for
  every environment.

Negative consequences:

- Kubernetes adds operational overhead compared with running a small number of
  VMs or managed app services.
- Engineers must understand Kubernetes primitives, Helm, OKE networking, and
  cluster recovery.
- Cluster failure becomes a platform-level incident and requires a tested
  disaster recovery procedure.

## Alternatives Considered

- OCI Compute VMs with Docker Compose: simpler initially, but harder to manage
  consistently across environments and weaker as an infrastructure-as-code
  deployment target.
- OCI Container Instances: useful for isolated containers, but not a strong fit
  for multi-service deployment, service discovery, Helm workflows, and
  namespace-based environments.
- Managed platform-as-a-service outside OCI: reduces operations but weakens OCI
  alignment and source-controlled infrastructure reproducibility.
- Non-OCI Kubernetes provider: technically viable but conflicts with the OCI
  infrastructure direction and would add cross-cloud networking and IAM
  complexity.
