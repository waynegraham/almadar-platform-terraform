# Architecture Simplification Report

Date: 2026-06-22

## Purpose

This report identifies where the current AlMadar infrastructure could be
simplified and deployed more easily while preserving the core platform
requirements:

- public Next.js frontend,
- Strapi CMS,
- Cantaloupe IIIF image service,
- approximately 100 GB of production IIIF source images,
- OCI Database with PostgreSQL managed service,
- OCI Object Storage as durable media storage,
- Cloudflare for DNS, TLS, CDN, and WAF.

The goal is not to remove infrastructure as code. The goal is to reduce the
number of moving parts an engineer must understand, deploy, and recover.

## Executive Recommendation

The largest simplification opportunity is to reduce Kubernetes operational
scope. The current architecture is sound, but OKE, Helm, External Secrets
Operator, Actions Runner Controller, namespaces, RBAC, and GitHub self-hosted
runners create a platform that is more complex than the current content scale
requires.

The simplest practical production architecture is:

- run Next.js, Strapi, and Cantaloupe as OCI container workloads or a small
  self-managed container host,
- keep OCI Database with PostgreSQL managed service for production data,
- keep OCI Object Storage for Strapi media and IIIF source images,
- keep Cloudflare in front of the public services,
- use GitHub-hosted runners for CI/CD unless OCI-hosted runners are explicitly
  required,
- keep Terraform for OCI network, Object Storage, PostgreSQL, Vault, and the
  application runtime.

If the team wants to keep Kubernetes, simplify within Kubernetes first: one
region, one OKE cluster, no Actions Runner Controller initially, no separate
managed PostgreSQL DB systems for every non-production environment, and no
persistent shared Cantaloupe cache unless measurements prove it is needed.

## Current Complexity Drivers

| Area | Why it adds complexity | Simplification option |
| --- | --- | --- |
| OKE | Requires cluster lifecycle, node pools, Kubernetes upgrades, RBAC, pod scheduling, Helm, service exposure, and recovery procedures | Use OCI container runtime services or a small VM/container host for the three app services. |
| Helm | Useful for repeatable Kubernetes deployment, but adds chart maintenance and values overlays | If leaving Kubernetes, replace Helm with container definitions and Terraform-managed service configuration. |
| External Secrets Operator | Good pattern for Kubernetes, but requires ESO installation, workload identity, ClusterSecretStore, ExternalSecrets, and sync debugging | Use OCI Vault references or CI/CD-injected secrets directly in the application runtime if not using Kubernetes. |
| Actions Runner Controller | Adds in-cluster deployment dependency, privileged runner concerns, and Docker-in-Docker capacity planning | Use GitHub-hosted runners for builds and deployments unless private OCI network access requires self-hosted runners. |
| Multi-region Terraform roots | Riyadh and Jeddah are useful for future DR but increase planning, naming, and cost decisions now | Make one primary region the default. Treat second-region deployment as a documented DR phase. |
| Separate dev/test/prod managed databases | Strong isolation but high cost and more operational surfaces | Keep production isolated. Use local Docker/k3d or one shared non-production managed PostgreSQL DB system if needed. |
| Cantaloupe persistent cache | Cache storage can create scheduling and replica consistency questions | Start with ephemeral cache plus Cloudflare caching. Source images remain durable in Object Storage. |
| Cloudflare manual configuration | Manual dashboard configuration can drift | Keep Cloudflare, but manage only critical records/rules as code at first. |

## Simplification Options

### Option 1: Keep Current OKE Architecture, Simplify Operations

This is the lowest-risk change from the current repository because it preserves
the existing Kubernetes and Helm direction.

Recommended changes:

- Use one active OCI region for production launch.
- Use OKE Basic Cluster unless Enhanced Cluster features are required.
- Keep one OKE node pool at launch.
- Remove Actions Runner Controller from the first production deployment.
- Use GitHub-hosted runners to build images and deploy with approved OCI
  credentials.
- Keep production PostgreSQL on OCI Database with PostgreSQL.
- Use one shared non-production PostgreSQL DB system only if shared cloud
  testing is required.
- Keep Cantaloupe derivative cache ephemeral or small.
- Defer default-deny NetworkPolicies until the service paths are final, but add
  namespace quotas and resource limits before production.

Pros:

- Smallest deviation from current Terraform and Helm investment.
- Keeps Kubernetes portability.
- Preserves a clear path to scale later.

Cons:

- Still requires Kubernetes knowledge to operate.
- Still requires Helm chart maintenance.
- Still has OKE node cost and cluster upgrade responsibility.

Best fit:

- The team expects to retain Kubernetes expertise or wants OKE as the long-term
  operating model.

## Option 2: Container Services Without Kubernetes

This option keeps managed data services and object storage, but removes OKE,
Helm, ARC, Kubernetes RBAC, and External Secrets Operator.

Target shape:

- Next.js runs as a containerized service.
- Strapi runs as a containerized service.
- Cantaloupe runs as a containerized service.
- OCI Database with PostgreSQL stores Strapi data.
- OCI Object Storage stores Strapi uploads and the 100 GB IIIF source image
  corpus.
- Cloudflare routes `www`, `cms`, `api`, and `iiif` hostnames to the OCI origin.
- Terraform manages networking, Object Storage, PostgreSQL, Vault, and
  container service definitions.

Pros:

- Removes Kubernetes control plane, node pools, Helm charts, ESO, and ARC.
- Easier for a small IT team to understand.
- Fewer cluster-specific recovery procedures.
- Better match for three long-running application services.

Cons:

- Less portable than Kubernetes.
- Some OCI container runtime choices may have fewer knobs than OKE.
- Migration requires replacing Helm deployment paths.
- Need to confirm the selected OCI runtime supports the required networking,
  secrets, persistent cache, and container image workflow.

Best fit:

- The team wants the simplest managed-container deployment and does not need
  Kubernetes-specific features.

## Option 3: Single Small VM Running Containers

This is the simplest operational architecture, but it trades away managed
runtime features.

Target shape:

- One OCI Compute VM runs Docker or Podman Compose for Next.js, Strapi, and
  Cantaloupe.
- OCI Database with PostgreSQL remains managed.
- OCI Object Storage remains the source of truth for media and IIIF images.
- Cloudflare fronts the VM.
- Terraform provisions the VM, network, Object Storage, PostgreSQL, Vault, and
  security rules.

Pros:

- Easiest to understand.
- Very fast to deploy.
- Minimal moving parts.
- Local Docker Compose maps closely to production.

Cons:

- VM patching, process supervision, log rotation, and host recovery become the
  team's responsibility.
- Rolling deployments are harder.
- High availability requires a second VM and load balancer.
- A host failure affects all app services until the VM is restored or replaced.

Best fit:

- A temporary launch architecture, pilot deployment, or low-budget staging
  environment.

## Recommended Path

Start with Option 1 if the team is already committed to OKE. Otherwise, choose
Option 2 as the simpler production target.

The recommended simplification sequence is:

1. Freeze production to one OCI region.
2. Keep OCI Database with PostgreSQL and OCI Object Storage as non-negotiable
   managed data services.
3. Remove Actions Runner Controller from the production launch scope.
4. Use GitHub-hosted runners and a documented break-glass deployment path.
5. Keep one production PostgreSQL DB system and avoid separate managed DB
   systems for `dev` and `test` unless required.
6. Keep Cantaloupe cache small and disposable; rely on Object Storage for source
   durability and Cloudflare for public derivative caching.
7. Defer multi-region deployment, OpenSearch, network firewall, private vault,
   and HSM keys until there is a documented requirement.
8. Add only the Terraform needed to recreate the chosen simpler runtime.

## What To Remove Or Defer First

| Item | Recommendation | Reason |
| --- | --- | --- |
| Actions Runner Controller | Defer | It couples deployment to the cluster being deployed and adds privileged runner operations. |
| Organization-scoped OCI runners | Defer | GitHub-hosted runners are easier unless private network access is mandatory. |
| Active Jeddah deployment | Defer | Keep Jeddah as a DR design until restore procedures are tested in one region. |
| Separate managed DB systems for dev/test | Defer | Cost and maintenance likely outweigh benefits at current scale. |
| Persistent shared Cantaloupe cache | Defer | Source images are in Object Storage and derivatives can be regenerated. |
| OKE Enhanced Cluster | Avoid initially | Use Basic Cluster unless a specific Enhanced feature is required. |
| OpenSearch | Continue deferring | PostgreSQL/application search is enough until product requirements prove otherwise. |
| OCI Network Firewall | Avoid initially | Cloudflare is already the edge WAF/CDN layer. |
| Private Vault/HSM keys | Avoid initially | Default Vault and software-protected keys are simpler and likely sufficient. |

## Deployment Workflow Simplification

Current intended workflow:

```text
GitHub Actions
  -> OCI self-hosted runner in OKE
  -> OCIR image build/push
  -> Helm upgrade
  -> OKE workloads
```

Simpler workflow:

```text
GitHub-hosted runner
  -> build immutable container images
  -> push to OCIR
  -> deploy to selected OCI runtime
  -> run smoke tests through Cloudflare/origin endpoints
```

This removes the need for ARC during initial launch. If private network access
is needed later, add self-hosted runners after the production app path is stable.

## Terraform Simplification

Keep Terraform, but reduce the number of independent stacks needed for launch.

Recommended launch stacks:

- `network`: one primary-region VCN, public load balancer subnet, private data
  subnet, private app subnet if needed.
- `object-storage`: `iiif-prod` and `strapi-prod` first; add non-production
  buckets only when shared cloud environments need them.
- `postgresql`: one production OCI Database with PostgreSQL DB system.
- `vault`: production application secrets.
- `runtime`: the chosen application runtime, either OKE or simpler container
  services.

Defer or make optional:

- second-region network,
- second-region Object Storage,
- non-production managed PostgreSQL systems,
- Actions Runner Controller resources,
- advanced Kubernetes RBAC and policy stacks until OKE is confirmed as the
  runtime.

## Operational Impact

Simplification should reduce:

- number of components to upgrade,
- number of credentials and service accounts,
- number of deployment failure modes,
- amount of Kubernetes-specific knowledge required,
- disaster recovery steps,
- baseline monthly cost for idle non-production systems.

Simplification should not reduce:

- durability of PostgreSQL data,
- durability of IIIF and Strapi media,
- ability to recreate infrastructure from source control,
- Cloudflare edge protection,
- documented backup and recovery procedures.

## Decision Matrix

| Criterion | Keep OKE, simplify | OCI container runtime | Single VM with containers |
| --- | --- | --- | --- |
| Lowest migration effort | High | Medium | Medium |
| Lowest operational complexity | Medium | High | High initially |
| Highest availability path | High | Medium | Low unless expanded |
| Lowest Kubernetes expertise required | Low | High | High |
| Best long-term scale path | High | Medium | Low |
| Best fit for current scale | Medium | High | Medium |

## Final Recommendation

For a small cultural heritage platform with approximately 1,000 objects and
100 GB of IIIF source images, the architecture can be simplified most by
removing Kubernetes-adjacent deployment machinery before production launch.

Keep the durable managed services: OCI Database with PostgreSQL, OCI Object
Storage, OCI Vault, and Cloudflare. Reevaluate whether OKE is necessary for only
three application services. If OKE remains, launch it in the smallest useful
form and defer ARC, multi-region deployment, separate non-production managed
databases, and persistent shared Cantaloupe caching.
