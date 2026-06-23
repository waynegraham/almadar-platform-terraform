# OCI Infrastructure Sizing and Cost Report

Date: 2026-06-23

## Purpose

This report recommends an initial Oracle Cloud Infrastructure sizing plan for
the simplified August 1, 2026 AlMadar launch. It is intended for budgeting and
implementation planning, not as a fixed quote.

Use the OCI Cost Estimator before procurement or production launch. OCI pricing
varies by region, currency, discounts, and usage.

## Planning Assumptions

- Current collection scale is approximately 1,000 collection objects.
- The platform serves a public Next.js frontend, a Strapi CMS, IIIF images
  through Cantaloupe, video, and audio.
- Launch media scale is approximately 100 GB of IIIF images, 50 GB of video,
  and 5 GB of audio.
- Production data should live in managed services, not on application VMs.
- Saudi government requirements require self-hosted GitHub Actions runners.
- The organization should prefer a small, boring, recoverable platform over
  speculative scale.
- The primary production region should be one OCI region, currently expected to
  be `me-riyadh-1`.

## Recommended Starting Size

| Area | Recommendation | Why |
| --- | --- | --- |
| Application runtime | 1 OCI Compute VM running Docker Compose | Simplest runtime for Next.js, Strapi, Cantaloupe, and a reverse proxy at current scale. |
| Application VM size | Start at 4 OCPUs and 24-32 GB RAM | Provides headroom for Strapi, frontend, Cantaloupe tile generation, proxy, Docker overhead, and cache activity. Adjust after measurement. |
| Application VM storage | Boot volume plus block volume for Docker data, logs, and Cantaloupe derivative cache | Do not store durable media on the VM. Size cache for performance, not for the full media corpus. |
| GitHub Actions runner | 1 separate OCI Compute VM | Required by policy and isolates build/deployment activity from public application workloads. |
| Runner VM size | Start at 2 OCPUs and 8-16 GB RAM | Enough for moderate Node/Docker builds. Increase if image builds are slow or memory-bound. |
| Production PostgreSQL | OCI Database with PostgreSQL managed service, 1 production DB system | Keeps Strapi data out of the VM and gives managed backup/restore primitives. |
| Object Storage | Standard-tier buckets or prefixes for Strapi uploads, IIIF images, video, and audio | Durable source of truth for media. Budget for at least 155 GB plus versions, uploads, and growth. |
| Cloudflare | DNS, TLS, CDN, WAF, Access | Keeps public edge controls outside the VM and reduces origin traffic. |
| Cantaloupe cache | Local disposable filesystem cache on the app VM | Source media remains durable in Object Storage. Add more cache only after measuring hit rates. |
| Kubernetes/OKE | 0 for launch | Not required for the first production release. |
| Load balancer | 0 initially if Cloudflare points directly to app VM; add 1 OCI Load Balancer only if a second app VM is introduced | Avoid a moving part until high availability requires it. |

## Cost-Bearing OCI Inventory

### Compute

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| Application VM | 1 | OCPU hours, memory GB hours, boot/block volume storage | Runs proxy, Next.js, Strapi, and Cantaloupe. |
| Runner VM | 1 | OCPU hours, memory GB hours, boot volume storage | Runs self-hosted GitHub Actions runner and build/deploy tooling. |
| Additional app VM | 0 initially | Same as app VM plus load balancing | Add only if recovery-time requirements demand VM redundancy. |
| OKE control plane and workers | 0 for launch | Cluster and worker costs if reintroduced | Deferred. |
| OCIR image storage | Repositories for frontend and Strapi images | Container image storage | Use immutable tags and retention rules. |

### Database

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Database with PostgreSQL, prod | 1 managed DB system | Provisioned compute, storage, backup retention | Start modestly and scale after real Strapi/admin/API measurements. |
| OCI Database with PostgreSQL, non-prod | 0 initially unless shared cloud testing requires it | Same as production if provisioned | Local Docker Compose should cover routine development. |
| PostgreSQL backups | 14 days minimum, 30 days if budget allows | Backup and storage-related usage | Recovery requirements should drive retention. |

### Storage

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Object Storage Standard buckets | Production buckets or prefixes for IIIF, Strapi uploads, video, and audio | GB stored per month and request volume | Budget for at least 155 GB raw media plus versions and growth. |
| Object versioning | Enable for production, lifecycle old versions | Previous versions consume storage | Use lifecycle policies to avoid uncontrolled growth. |
| Object requests | Usage-based | Request count | IIIF and media access can create many reads; cache public derivatives and media at Cloudflare. |
| App VM block volume | 1 cache/log volume | GB/month and performance settings | Disposable operational data only. |

### Networking

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| Public IP for app VM | 1 | Public IP and data transfer pricing as applicable | Cloudflare should be the normal public entrypoint. |
| Public IP or private admin access for runner VM | 1 or private-only with approved access path | Public IP and data transfer pricing as applicable | Restrict SSH/admin access. |
| NAT Gateway | 1 if VMs are private or need controlled outbound internet | Gateway and processed traffic, depending current pricing | Public subnet deployment may avoid NAT but increases exposure. |
| Service Gateway | 1 per VCN | Usually no direct gateway charge, verify current pricing | Prefer private access to OCI Object Storage where practical. |
| Load Balancer | 0 initially | Load balancer hour and bandwidth units | Add with a second app VM. |
| Outbound data transfer | Usage-based | GB egress over regional allowances | Cloudflare caching should reduce OCI origin egress. |

### Secrets and Security

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Vault default vault | 1 if used | Vault/secret/key pricing depends on vault type and key type | Keep secrets out of Git and production env examples. |
| Private Vault | 0 initially | Virtual private vault per hour | Do not use without compliance requirement. |
| OCI Network Firewall | 0 initially | Instance/request/data processing charges | Cloudflare is already the public WAF/CDN layer. |

### Observability and Operations

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Logging or host log retention | Conservative retention | Log storage/ingestion or block volume usage | Keep application log volume intentional and rotated. |
| OCI Monitoring | Required alarms | Metrics and alarm usage | Alert on VM health, disk usage, PostgreSQL, and public endpoint failures. |
| Notifications | Required operational alerts only | Delivery operations | Use for production alarms and backup failure notifications. |

## Recommended Environment Plan

### Production

- One application VM running Docker Compose.
- One runner VM for self-hosted GitHub Actions.
- One OCI Database with PostgreSQL managed DB system.
- Production Object Storage buckets or prefixes for IIIF, Strapi uploads,
  video, and audio.
- Cloudflare fronting frontend, CMS/API, and IIIF endpoints.
- OCIR repositories for immutable app images.

### Test

- Prefer the same application VM pattern only if shared staging is required.
- Otherwise use local Docker Compose and validation tests.
- Use separate Object Storage buckets or prefixes if cloud test media is
  required.

### Development

- Local Docker Compose should remain the default daily development path.
- Do not provision always-on managed development infrastructure unless the team
  needs shared integration state.

## Scaling Triggers

Increase application VM size when:

- sustained CPU exceeds 60-70% during normal traffic,
- Cantaloupe tile generation causes sustained CPU saturation,
- Strapi admin/API latency correlates with VM CPU or memory pressure,
- Docker containers restart due to memory pressure,
- local cache/log volume regularly exceeds planned utilization.

Increase runner VM size when:

- Docker builds are consistently slow,
- Node builds fail or swap due to memory pressure,
- deployment jobs compete with image builds.

Increase PostgreSQL when:

- sustained CPU exceeds 60-70%,
- memory pressure or connection saturation appears,
- Strapi admin/API latency correlates with database waits,
- storage growth or backup windows exceed operational targets.

Add a second application VM and load balancer when:

- required recovery time is shorter than app VM rebuild time,
- planned maintenance cannot tolerate downtime,
- traffic measurements justify horizontal redundancy.

## Items Not Recommended Initially

- OKE/Kubernetes.
- Helm production deployment.
- Actions Runner Controller.
- Active multi-region deployment in both Riyadh and Jeddah.
- OpenSearch.
- OCI Network Firewall in addition to Cloudflare.
- Private Vault or HSM-protected keys without a compliance requirement.
- Large persistent Cantaloupe cache sized to the full media corpus.
- Separate managed DB systems for every non-production environment.

## Cost Estimator Inputs

Use these inputs as the first OCI Cost Estimator pass:

- Region: `me-riyadh-1`.
- Compute: 1 app VM, 4 OCPUs, 24-32 GB RAM.
- Compute: 1 runner VM, 2 OCPUs, 8-16 GB RAM.
- Block Volume: app VM cache/log volume plus boot volumes.
- PostgreSQL: 1 OCI Database with PostgreSQL managed DB system, 14-30 days
  backup retention.
- Object Storage: at least 155 GB raw launch media plus Strapi uploads,
  previous object versions, and growth.
- OCIR: frontend and Strapi image repositories with retention.
- Load Balancer: 0 initially; add only if introducing a second app VM.
- Vault: Default Vault with software-protected key and secrets if used.
- Logging/Monitoring: estimate log retention and alarm usage.
- Networking: estimate outbound data transfer after Cloudflare caching.

## Source Notes

- OCI Terraform provider documentation includes resource families for Compute,
  networking, Object Storage, Vault/secrets, container repositories, and related
  infrastructure used by this plan.
- Oracle's public price list should be used before procurement for current
  compute, storage, networking, database, and logging rates:
  <https://www.oracle.com/cloud/price-list/>
