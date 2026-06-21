# ADR-005: Single OKE Cluster with Namespaces

Date: 2026-06-21

Status: Accepted

## Context

The platform currently supports a small set of services: Next.js, Strapi,
Cantaloupe, PostgreSQL integration, object storage integration, and CI/CD
runners. The expected content scale is modest. The repository's operating
principle is simplicity before scale.

The platform needs distinct `dev`, `test`, and `prod` environments, but there is
not currently a documented business requirement for multiple Kubernetes
clusters.

## Decision

Use a single OKE cluster with Kubernetes namespaces for environments.

Create and manage these namespaces:

- `dev`
- `test`
- `prod`

Use namespace-scoped RBAC, Helm values, and secrets to separate workloads and
configuration. Additional clusters require a new ADR and documented business or
operational justification.

## Consequences

Positive consequences:

- Lower OCI cost than operating one cluster per environment.
- Simpler Terraform, CI/CD, monitoring, and disaster recovery.
- Faster environment creation through namespace and Helm configuration.
- Shared cluster capacity is appropriate for the current platform size.

Negative consequences:

- Cluster-level failure affects all environments.
- Strong isolation depends on namespace boundaries, RBAC, network policy, and
  disciplined deployment practices.
- Noisy workloads in one namespace can affect other namespaces if resource
  requests and limits are not enforced.
- Production and non-production workloads share control plane dependencies.

## Alternatives Considered

- One OKE cluster per environment: stronger isolation, but higher cost and
  operational overhead than justified by current scale.
- Separate production cluster with shared non-production cluster: likely future
  option if isolation or compliance requirements increase, but not required now.
- Multiple regional clusters from the start: rejected as premature complexity.
- No Kubernetes namespaces, only naming conventions: rejected because namespaces
  provide clearer scoping for RBAC, secrets, and Helm releases.
