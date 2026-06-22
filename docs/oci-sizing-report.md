# OCI Infrastructure Sizing and Cost Report

Date: 2026-06-22

## Purpose

This report recommends an initial Oracle Cloud Infrastructure sizing plan for
the AlMadar platform and lists the OCI resources that can create recurring or
usage-based cost. It is intended for budgeting and implementation planning, not
as a fixed quote.

Use the OCI Cost Estimator before procurement or production launch. OCI pricing
varies by region, currency, discounts, and usage. Oracle's public price list
also shows that many relevant resources are metered by different units:
compute by OCPU and memory hours, OKE Enhanced Cluster by cluster hour, load
balancers by load balancer hour and bandwidth, PostgreSQL by OCPU and storage,
Object Storage by capacity and requests, and logging/monitoring by usage.

## Planning Assumptions

- Current collection scale is approximately 1,000 collection objects.
- The platform serves a public Next.js frontend, a Strapi CMS, and IIIF images
  through Cantaloupe.
- Cantaloupe will serve approximately 100 GB of production IIIF source images
  from OCI Object Storage at launch.
- Production data should live in managed services, not in application pods.
- The organization should prefer a small, boring, recoverable platform over
  speculative scale.
- The primary production region should be one OCI region, currently expected to
  be `me-riyadh-1`. A second active region should be treated as a disaster
  recovery project with separate budget approval.

## Recommended Starting Size

| Area | Recommendation | Why |
| --- | --- | --- |
| OKE cluster | Single production OKE cluster, Basic Cluster if feature requirements allow | Basic Cluster avoids the OKE Enhanced Cluster hourly charge. Use Enhanced only if the team needs features that justify the recurring cluster cost. |
| OKE worker nodes | 3 managed worker nodes, `VM.Standard.E4.Flex` or current regional successor, 2 OCPUs and 16 GB RAM each | Provides enough headroom for frontend, CMS, Cantaloupe, system pods, rolling deploys, and one node failure while staying modest. |
| Production PostgreSQL | OCI Database with PostgreSQL managed service, 1 DB system, 1 instance, `VM.Standard.E4.Flex`, 2 OCPUs, 16 GB RAM, optimized storage, 14-30 day backups | Matches current Terraform defaults and keeps production data out of Kubernetes and self-managed compute. Increase after real query and editor workload measurements. |
| Object Storage | Six Standard-tier buckets: `iiif-dev`, `iiif-test`, `iiif-prod`, `strapi-dev`, `strapi-test`, `strapi-prod`, versioning enabled, old previous versions deleted after 180 days. Budget at least 100 GB for `iiif-prod` source images at launch. | Keeps media outside pods and separates environments. Version lifecycle limits storage growth from replaced assets, but previous versions and non-production copies can increase billed storage beyond the raw 100 GB corpus. |
| Load balancing | One public flexible OCI Load Balancer for application ingress, minimum 10 Mbps and maximum 100 Mbps to start | Enough for a small public site behind Cloudflare. Increase only after measured origin traffic requires it. |
| Cantaloupe cache | Start with per-pod or small PVC cache, 10 GiB as currently documented | The 100 GB source corpus remains in Object Storage. Cantaloupe cache stores generated derivatives and should be treated as disposable. Increase cache only after measuring hot tile reuse and Cloudflare cache hit ratio. |
| GitHub Actions runners | Keep ARC `minRunners=0`; reduce initial `maxRunners` from 10 to 2-3 unless concurrent build demand is proven | Runner pods consume OKE node CPU and memory. A max of 10 can force larger worker nodes or more nodes. |
| Non-production | Run `dev` and `test` in the same cluster with low replica counts. Avoid separate OCI Database with PostgreSQL DB systems unless isolation is required. | Non-production managed databases and always-on replicas can dominate costs for a small platform. |
| Observability | Use default OCI metrics and keep logging retention conservative | OCI Logging has free included storage, then usage-based cost. Keep retention and ingestion intentional. |

## Cost-Bearing OCI Inventory

### Compute and Kubernetes

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OKE control plane | 1 cluster | Basic Cluster is listed as free; Enhanced Cluster is billed per cluster hour | Terraform currently defaults `cluster_type` to `ENHANCED_CLUSTER`. For nonprofit cost control, use `BASIC_CLUSTER` unless Enhanced features are required. |
| OKE worker compute | 3 nodes x 2 OCPUs x 16 GB RAM | OCPU hours, memory GB hours, boot volume storage | Flexible shapes bill CPU and memory separately. Boot volumes are billed as Block Volume storage. |
| ARC runner pods | 0 idle, burst to 2-3 initially | Same worker node capacity as other Kubernetes pods | Runners do not create direct OCI compute charges by themselves, but they require enough worker capacity. High concurrency may require larger or additional nodes. |
| OCIR image storage | One repository set for frontend and Strapi images | Container image storage, same basis as Object Storage Standard | Production images should be immutable. Keep retention rules so old images do not accumulate indefinitely. |

### Database

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Database with PostgreSQL, prod | 1 managed DB system, 1 instance, 2 OCPUs, 16 GB RAM | Provisioned OCPUs, selected memory/resources, optimized storage usage, backup retention | This should be Oracle's managed PostgreSQL service, provisioned by `infrastructure/terraform/modules/managed-postgresql`, not PostgreSQL inside OKE. |
| OCI Database with PostgreSQL, dev/test | Prefer shared non-production managed DB system or local/k3d for routine work | Same as production if provisioned | Separate managed DB systems for every non-prod environment are cleaner but likely expensive relative to project scale. |
| PostgreSQL backups | 14 days minimum, 30 days for production if budget allows | Backup and storage-related usage | Longer retention improves recovery but increases storage cost. |

### Storage

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Object Storage Standard buckets | 6 buckets, with at least 100 GB in `iiif-prod` at launch | GB stored per month and request volume | IIIF source images and Strapi uploads are durable platform assets. Cloudflare should absorb repeat public image traffic where possible. |
| Object versioning | Enabled | Previous object versions consume storage until lifecycle deletion | The 100 GB production corpus can cost more than 100 GB if images are replaced and previous versions are retained. Current lifecycle deletes previous versions after 180 days. Shorten for non-production if storage grows. |
| Object requests | Usage-based | Request count | IIIF tile access can create many reads. Cache aggressively at Cloudflare for public image derivatives. |
| Cantaloupe PVC or Block Volume | 10 GiB to start | Block Volume GB/month and performance units if changed | Treat as cache, not source of truth. Do not size this to the 100 GB image corpus unless measurements show local derivative cache capacity is the bottleneck. |

### Networking

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Load Balancer | 1 public flexible LB | Load balancer hour and bandwidth units | Put Cloudflare in front and keep the origin LB small at launch. |
| NAT Gateway | 1 per active VCN/region | NAT gateway service and/or processed traffic, depending current OCI pricing | Needed for private worker nodes to reach the internet for image pulls and updates. A Service Gateway can reduce NAT usage for OCI service traffic. |
| Service Gateway | 1 per active VCN/region | Usually no direct gateway charge, but verify current regional pricing | Use for private access to OCI Object Storage and other Oracle services to reduce public/NAT paths. |
| Internet Gateway | 1 per active VCN/region | Usually no direct gateway charge; outbound data transfer can apply | Required for public load balancer paths. |
| Outbound data transfer | Usage-based | GB egress over regional free allowance | Cloudflare caching should reduce OCI origin egress for static assets and IIIF derivatives. |
| DNS | Prefer Cloudflare DNS, not OCI DNS | OCI DNS is query-metered if used | Current architecture assigns DNS responsibility to Cloudflare. |

### Secrets and Security

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Vault default vault | 1 vault | Default Vault software-protected keys and secrets are listed as free on the public price list | Current Terraform uses `vault_type = "DEFAULT"`. Keep this unless compliance requires a private vault or HSM-backed keys. |
| Private Vault | 0 initially | Virtual private vault per hour | Do not use without a documented security or compliance requirement. |
| HSM-protected key versions | 0 initially | Key version per month beyond free allowances | Software-protected keys are adequate for this baseline unless policy requires HSM. |
| OCI WAF / Network Firewall | 0 initially | Instance, request, and/or data processing charges | Cloudflare is already the documented WAF/CDN layer. Do not duplicate unless there is a specific requirement. |

### Observability and Operations

| Resource | Recommended quantity | Cost driver | Notes |
| --- | ---: | --- | --- |
| OCI Logging | Conservative retention | First included allowance is free, then GB log storage per month | Keep application log volume moderate and set retention intentionally. |
| OCI Monitoring | Default metrics plus required alarms | Included allowance, then datapoint ingestion/retrieval | Use alarms for availability, node health, database CPU/storage, and load balancer health. |
| Notifications | Required operational alerts only | Included allowance, then delivery operations | Use for production alarms and backup failure notifications. |

## Kubernetes Capacity Check

The production Helm values currently request approximately:

| Workload | Replicas | CPU request | Memory request |
| --- | ---: | ---: | ---: |
| Frontend | 2 | 500m total | 1 GiB total |
| Strapi | 2 | 1000m total | 2 GiB total |
| Cantaloupe | 2 | 500m total | 1.5 GiB total |
| ARC controller | 1 | 100m | 128 MiB |
| One active runner | 1 | 500m | 1 GiB |

Three 2-OCPU / 16-GB worker nodes provide 6 OCPUs and 48 GB RAM before system
overhead. This is enough for the current app requests, rolling deployments, and
a small number of active runner pods. CPU, not memory, is the limiting resource
if many runner jobs start at once.

## Recommended Environment Plan

### Production

- One OKE cluster with three worker nodes.
- One OCI Database with PostgreSQL managed DB system.
- Production Object Storage buckets for IIIF and Strapi media, including about
  100 GB of IIIF source images in `iiif-prod`.
- OCI Vault default vault and software-protected key.
- One public OCI Load Balancer behind Cloudflare.
- ARC enabled with zero idle runners and a low initial concurrency cap.

### Test

- Same OKE cluster, `test` namespace.
- One replica per application unless testing release behavior requires two.
- Prefer shared non-production OCI Database with PostgreSQL or a single smaller
  managed DB system.
- Use separate `iiif-test` and `strapi-test` buckets.
- Keep backup and log retention shorter than production.

### Development

- Local Docker Compose should remain the default daily development path.
- Use the `dev` namespace for integration checks that specifically require
  Kubernetes behavior.
- Avoid always-on managed development databases unless the team needs shared
  integration state.

## Scaling Triggers

Increase OKE worker size or count when:

- sustained node CPU exceeds 60-70% during normal traffic,
- rolling deploys cannot schedule without evicting healthy pods,
- ARC jobs regularly wait for capacity,
- Cantaloupe tile generation causes sustained CPU saturation.

Increase PostgreSQL when:

- sustained CPU exceeds 60-70%,
- memory pressure or connection saturation appears,
- Strapi admin/API latency correlates with database waits,
- storage growth or backup windows exceed operational targets.

Increase Object Storage and caching controls when:

- IIIF tile requests materially increase origin reads,
- Cloudflare cache hit ratio is low for immutable IIIF derivatives,
- previous object versions grow faster than expected,
- `iiif-prod` grows materially beyond the initial 100 GB source image corpus,
- restored-object testing shows lifecycle settings are too aggressive.

## Items Not Recommended Initially

- Separate production OKE cluster for each environment.
- Active multi-region deployment in both Riyadh and Jeddah.
- OpenSearch.
- OCI Network Firewall in addition to Cloudflare.
- Private Vault or HSM-protected keys without a compliance requirement.
- Large persistent Cantaloupe cache volumes.
- High ARC runner concurrency before measuring build demand.

## Cost Estimator Inputs

Use these inputs as the first OCI Cost Estimator pass:

- Region: `me-riyadh-1`.
- OKE: 1 Basic Cluster, or 1 Enhanced Cluster if chosen intentionally.
- Compute: 3 x `VM.Standard.E4.Flex`, 2 OCPUs, 16 GB RAM, boot volumes.
- Load Balancer: 1 flexible load balancer, 10 Mbps minimum, 100 Mbps maximum.
- PostgreSQL: 1 OCI Database with PostgreSQL managed DB system, 1 instance,
  2 OCPUs, 16 GB RAM, optimized storage, 14-30 days backup retention.
- Object Storage: start with 100 GB for `iiif-prod` source images, then add
  Strapi media, non-production IIIF copies, previous object versions, and
  container images.
- Block Volume: worker boot volumes plus 10 GiB Cantaloupe cache PVC if using
  persistent cache.
- Vault: Default Vault with software-protected key and secrets.
- Logging: estimate monthly log storage beyond the free included amount.
- Networking: estimate outbound data transfer after Cloudflare caching.

## Source Notes

- Oracle's public price list documents OCPU and memory-based compute pricing,
  boot volume billing, OKE Basic versus Enhanced Cluster billing, load balancer
  billing units, outbound data transfer units, PostgreSQL billing drivers,
  Object Storage and Block Volume units, and Vault/KMS/Secrets cost categories:
  <https://www.oracle.com/cloud/price-list/>
- OCI documentation supports flexible OKE node shape configuration and flexible
  load balancer sizing through Kubernetes service annotations.
