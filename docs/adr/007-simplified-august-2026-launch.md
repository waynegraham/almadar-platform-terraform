# ADR-007: Simplified August 2026 Launch

Date: 2026-06-23

Status: Accepted

## Context

The project has a tight August 1, 2026 production deadline and a modest launch
scale: approximately 1,000 works, 2,500 images, 100 GB of IIIF image data,
50 GB of video, 5 GB of audio, and a few dozen public pages.

The existing repository contains OKE, Helm, External Secrets Operator, Actions
Runner Controller, Kubernetes namespaces, managed PostgreSQL, Object Storage,
Cloudflare, and supporting runbooks. The managed data and media services remain
appropriate, but Kubernetes is not required for the first production launch.

Saudi government requirements also require self-hosted GitHub Actions runners.
For launch, a standalone OCI runner VM is simpler than running Actions Runner
Controller inside Kubernetes.

## Decision

For the August 1 launch:

- Use one primary OCI region, `me-riyadh-1`.
- Do not use OKE/Kubernetes for the launch runtime.
- Run production applications on one OCI Compute VM with Docker Compose.
- Run the self-hosted GitHub Actions runner on a separate OCI Compute VM.
- Run Next.js, Strapi, Cantaloupe, and Caddy or nginx as containers.
- Use OCI Database with PostgreSQL managed service for Strapi data.
- Use OCI Object Storage for Strapi uploads, IIIF source images, video, and
  audio.
- Use local VM disk only for Docker data, logs, and Cantaloupe derivative
  cache.
- Use Cloudflare for DNS, TLS, CDN, WAF, and admin access controls.
- Build immutable frontend and Strapi images on the OCI self-hosted runner.
- Push images to OCIR.
- Deploy to the app VM over SSH using Docker Compose.
- Defer OKE, Helm, External Secrets Operator, and Actions Runner Controller.

## Consequences

Benefits:

- Removes cluster lifecycle, node pools, Helm releases, Kubernetes RBAC,
  External Secrets Operator, and ARC from the launch path.
- Keeps durable data in managed OCI services.
- Keeps the production runtime close to the local Docker Compose model.
- Provides the required self-hosted GitHub Actions execution path.
- Reduces launch-time infrastructure concepts an operator must understand.

Tradeoffs:

- One application VM is not highly available by itself.
- VM patching, Docker maintenance, log rotation, and host recovery are the
  team's responsibility.
- Rolling deployments are simpler but less sophisticated than Kubernetes.
- Lower recovery-time objectives may require a second app VM and load balancer
  after the single-VM path is proven.

## Follow-Up

- Build Terraform for the app VM and runner VM.
- Add production Compose files under `deploy/compose`.
- Rewrite launch docs around VM + Docker Compose.
- Test app VM rebuild from Terraform, OCIR images, PostgreSQL backups, and
  Object Storage media.
- Reassess OKE only after launch if measured scale, availability requirements,
  or staffing make Kubernetes worth the operational cost.
