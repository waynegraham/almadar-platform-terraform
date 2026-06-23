# August 1 Production Simplification Plan

Date: 2026-06-23

Target launch date: August 1, 2026

## Purpose

This plan simplifies the AlMadar production launch architecture around the
actual launch scale:

- approximately 1,000 works,
- approximately 2,500 images,
- approximately 100 GB of IIIF image data,
- approximately 50 GB of video,
- approximately 5 GB of audio,
- only a few dozen public pages,
- Saudi government requirement for self-hosted GitHub Actions runners.

The launch goal is strong performance and reliability with as few moving parts
as possible. Kubernetes and OKE are not required for this scale and should not
be in the August 1 production path unless a concrete requirement appears that
Docker Compose on OCI Compute cannot satisfy.

## Executive Recommendation

Use a two-VM OCI production runtime:

- one OCI Compute VM runs Docker Compose for Next.js, Strapi, Cantaloupe, and
  Caddy or nginx,
- one separate OCI Compute VM runs the self-hosted GitHub Actions runner,
- OCI Database with PostgreSQL stores Strapi data,
- OCI Object Storage stores Strapi uploads, IIIF source images, video, and
  audio,
- Cloudflare fronts all public traffic,
- the application VM uses local disk only for Docker data, logs, and
  Cantaloupe derivative cache.

This keeps the durable data layer managed, keeps media out of containers and
VM-local filesystems, and removes the launch burden of OKE, Helm, Kubernetes
RBAC, External Secrets Operator, Actions Runner Controller, node pools, cluster
upgrades, and Kubernetes disaster recovery.

## Target Production Architecture

```text
Cloudflare
  -> OCI application VM public origin
       -> Caddy/nginx reverse proxy
       -> Next.js container
       -> Strapi container
       -> Cantaloupe container
       -> local Docker volumes for logs/cache only

GitHub
  -> separate OCI runner VM
       -> self-hosted GitHub Actions runner
       -> builds frontend and Strapi images
       -> pushes to OCIR
       -> deploys to application VM over SSH

Managed OCI services
  -> OCI Database with PostgreSQL
  -> OCI Object Storage buckets
  -> OCI Vault or documented secret injection process
```

Public hostnames should terminate at Cloudflare and route to the reverse proxy
on the application VM. Suggested hostname split:

- `www` or apex: Next.js frontend,
- `cms`: Strapi admin and API, protected with Cloudflare Access,
- `iiif`: Cantaloupe IIIF image service,
- media asset hostnames or paths: Object Storage via Strapi URLs and
  Cloudflare cache policy where appropriate.

## 1. What To Keep

Keep these pieces for launch:

| Item | Keep as | Reason |
| --- | --- | --- |
| `apps/frontend` | Production app | Next.js remains the public website. Build immutable image from `apps/frontend/Dockerfile`. |
| `apps/strapi` | Production app | Strapi remains the CMS. Build immutable image from `apps/strapi/Dockerfile`. |
| Cantaloupe | Production app | Required for IIIF image delivery from Object Storage. Keep cache disposable. |
| Docker Compose | Local and production runtime pattern | The production runtime should look like the existing local workflow, but with managed PostgreSQL/Object Storage and production images. |
| OCI Database with PostgreSQL | Managed data service | Durable CMS database should not live on the VM. |
| OCI Object Storage | Managed media service | Source images, Strapi uploads, video, and audio should not live on the VM. |
| Cloudflare | Public edge | DNS, TLS, CDN, WAF, cache rules, and admin access controls. |
| Self-hosted GitHub Actions runner | Separate OCI VM | Required by Saudi government constraints. Keep it outside the app VM. |
| OCIR | Image registry | Store immutable frontend and Strapi images. |
| Terraform network module | Modify and keep | Keep one VCN with app, runner, and data access controls. |
| Terraform managed PostgreSQL module | Keep | Already aligned with target architecture. |
| Terraform object-storage module | Extend and keep | Add/confirm buckets for IIIF, Strapi uploads, video, and audio. |
| Terraform Vault/secrets module | Keep if used operationally | Useful for source-of-truth secrets, even if Compose receives secrets through env files generated during deployment. |
| `tests/validation` | Keep and adapt | Smoke tests should validate the VM + Cloudflare paths after deployment. |
| `infrastructure/cantaloupe/cantaloupe.properties` | Keep | Reuse as the production Cantaloupe baseline with OCI Object Storage settings. |
| `infrastructure/minio` and local PostgreSQL init | Keep for local development | MinIO/PostgreSQL remain local substitutes for OCI services. |

## 2. What To Remove

Remove these from the launch path. Deletion can happen after the VM path is
working in `dev` or `test`; until then, mark them deprecated to avoid losing a
rollback reference.

| Item | Recommendation | Reason |
| --- | --- | --- |
| `infrastructure/helm/frontend` | Remove from active launch path | Helm is unnecessary without Kubernetes. |
| `infrastructure/helm/strapi` | Remove from active launch path | Compose should run the immutable Strapi image and a one-off migration command. |
| `infrastructure/helm/cantaloupe` | Remove from active launch path | Compose should run Cantaloupe directly. |
| `infrastructure/helm/actions-runner-controller` | Remove | Runner will be a separate VM, not ARC in Kubernetes. |
| `infrastructure/kubernetes/actions-runner-controller` | Remove | Replaced by VM runner provisioning and runner install docs. |
| `infrastructure/kubernetes/external-secrets` | Remove | External Secrets Operator is Kubernetes-specific. |
| `infrastructure/terraform/environments/oke` | Remove from launch path | OKE is not part of the August 1 architecture. |
| `infrastructure/terraform/environments/oke-rbac` | Remove | Kubernetes RBAC is not needed for Compose. |
| `infrastructure/terraform/modules/kubernetes` | Remove or archive | No cluster should be provisioned for launch. |
| `infrastructure/terraform/modules/kubernetes-rbac` | Remove or archive | No Kubernetes namespaces or RBAC are needed. |
| OKE-focused deployment docs | Rewrite | Current docs still describe OKE as production. They should point to VM + Compose. |
| ARC-focused runner docs | Rewrite | The runner architecture is now a standalone OCI VM. |

Do not remove local Docker Compose, app Dockerfiles, object storage code paths,
managed PostgreSQL Terraform, or Cloudflare documentation.

## 3. What To Defer

Defer these until after August 1 unless a launch-blocking requirement appears:

| Item | Defer until | Reason |
| --- | --- | --- |
| OKE/Kubernetes | Traffic, staffing, or compliance requirements justify it | Current scale does not need cluster operations. |
| Helm | Kubernetes is reintroduced | Compose is enough for four containers. |
| Actions Runner Controller | Kubernetes is reintroduced and VM runners are insufficient | ARC adds privileged Kubernetes runner operations. |
| Multi-region active deployment | Restore procedures are proven in one region | Active-active or warm standby adds operational load. |
| Multiple app VMs behind a load balancer | Availability target requires VM failure tolerance | Launch can start with one app VM plus a tested rebuild/restore procedure. |
| Persistent shared Cantaloupe cache | Cache miss rates or tile latency prove a need | Derivatives can be regenerated and Cloudflare should absorb public repeat traffic. |
| OpenSearch | Search requirements exceed PostgreSQL/application search | Current content scale is small. |
| Service mesh | Never for launch | Adds no launch value. |
| OCI Network Firewall in addition to Cloudflare | Specific security requirement | Cloudflare is already the public WAF/CDN edge. |
| Private Vault or HSM keys | Compliance requires them | Default Vault and software-protected keys are simpler. |
| Separate managed dev/test databases | Budget and workflow require shared cloud non-prod | Local Compose should remain default for daily development. |

## 4. Proposed New Directory Structure

Target structure:

```text
apps/
  frontend/
  strapi/

deploy/
  compose/
    production.compose.yml
    production.env.example
    caddy/
      Caddyfile
    nginx/
      nginx.conf
    systemd/
      almadar-compose.service
    scripts/
      deploy.sh
      backup-compose-config.sh
      restore-compose-config.sh
      run-strapi-migrations.sh
  runner/
    install-runner.sh
    runner.env.example
    systemd/
      github-runner.service

infrastructure/
  cantaloupe/
    cantaloupe.properties
  minio/
    init-buckets.sh
  postgresql/
    init.sql
  terraform/
    modules/
      compute-vm/
      managed-postgresql/
      network/
      object-storage/
      vault-secrets/
    environments/
      prod/
        main.tf
        variables.tf
        outputs.tf
        terraform.tfvars.example
      nonprod/
        main.tf
        variables.tf
        outputs.tf
        terraform.tfvars.example

docs/
  cloudflare.md
  platform-overview.md
  production-deployment-plan.md
  runbooks/
    disaster-recovery.md
    vm-patching.md
    database-restore.md
    object-storage-restore.md
  adr/
    007-simplified-august-2026-launch.md

tests/
  validation/
```

Notes:

- `deploy/compose/production.compose.yml` should be production-only and should
  not include local PostgreSQL or MinIO.
- Root `docker-compose.yml` should remain local development only.
- `deploy/compose/production.env.example` documents required variables but
  must not contain secrets.
- `deploy/compose/scripts/deploy.sh` should pull pinned image tags, run Strapi
  migrations, restart services, and run health checks.
- `deploy/runner` should document a single-purpose self-hosted runner VM,
  preferably with one runner group and labels such as `oci`, `prod-deploy`, and
  `self-hosted`.

## 5. Migration Plan

### Phase 0: Freeze The Launch Decision

Deliverables:

- Update ADR-007 to state VM + Docker Compose is the accepted August 1 launch
  architecture.
- Update `docs/platform-overview.md` so production no longer describes OKE as
  the default runtime.
- Update `docs/production-deployment-plan.md` around Compose deployment rather
  than Helm deployment.
- Mark OKE/Helm/ARC docs as deferred or archive them under a clear
  `docs/archive/` path.

Exit criteria:

- A new engineer can identify the launch architecture from the README and docs
  without encountering conflicting OKE instructions.

### Phase 1: Add Production Compose Runtime

Deliverables:

- Create `deploy/compose/production.compose.yml` with services:
  - `proxy` using Caddy or nginx,
  - `frontend` from OCIR immutable image,
  - `strapi` from OCIR immutable image,
  - `cantaloupe` from a pinned Cantaloupe image.
- Use managed services only:
  - no PostgreSQL container,
  - no MinIO container,
  - no source media bind mounts.
- Add named volumes only for:
  - proxy state/config if needed,
  - Docker/container logs if not using the host logging driver,
  - Cantaloupe derivative cache.
- Add health checks for all services.
- Add `deploy/compose/production.env.example`.
- Add systemd unit to start Compose on boot.

Exit criteria:

- A clean OCI-like VM can run all four production containers with managed
  PostgreSQL and Object Storage settings.

### Phase 2: Add OCI VM Terraform

Deliverables:

- Add `infrastructure/terraform/modules/compute-vm`.
- Provision one application VM with:
  - Docker Engine or Podman,
  - Compose plugin,
  - restricted ingress from Cloudflare where practical,
  - SSH ingress restricted to approved admin/runner sources,
  - block volume sized for Docker data, logs, and Cantaloupe cache only.
- Provision one runner VM with:
  - GitHub runner prerequisites,
  - Docker build tooling if image builds happen there,
  - no public app ports,
  - SSH restricted to approved admins.
- Keep OCI Database with PostgreSQL private.
- Keep Object Storage access through service gateway where practical.

Initial sizing:

- Application VM: start with 4 OCPUs and 24-32 GB RAM if budget allows; reduce
  only after Cantaloupe tile generation and Strapi build/runtime memory are
  measured.
- Runner VM: start with 2 OCPUs and 8-16 GB RAM; increase if Docker builds are
  slow or memory-bound.
- App VM block volume: enough for Docker images, logs, and derivative cache;
  do not size it for the 155 GB durable media corpus because media belongs in
  Object Storage.

Exit criteria:

- Terraform can recreate the network, app VM, runner VM, managed PostgreSQL,
  Object Storage buckets, and required secret references.

### Phase 3: Rework CI/CD For Self-Hosted Runner

Deliverables:

- Change `.github/workflows/frontend.yml` and `.github/workflows/strapi.yml`
  from `ubuntu-latest` to the OCI self-hosted runner labels required by policy.
- Keep immutable image builds and pushes to OCIR.
- Add a deployment workflow that:
  - runs only from protected branches/environments,
  - uses the self-hosted runner,
  - SSHes to the app VM,
  - writes or selects the approved image tags,
  - runs `docker compose pull`,
  - runs Strapi migrations,
  - restarts changed services,
  - runs smoke tests.
- Keep deployment credentials out of Git. Use GitHub environment secrets,
  runner-local credentials, or OCI Vault-backed injection with documented
  rotation.

Exit criteria:

- A `main` deployment can rebuild images, deploy the app VM, and run validation
  without GitHub-hosted runners.

### Phase 4: Move Data Paths To Managed Services

Deliverables:

- Confirm Strapi upload provider writes to OCI Object Storage.
- Confirm IIIF source images live in the production IIIF bucket.
- Add buckets or prefixes for video and audio.
- Confirm Cantaloupe reads from Object Storage and does not require local image
  files.
- Configure Cloudflare cache rules for IIIF derivatives and public media.
- Confirm signed/private media behavior where required by editorial policy.

Exit criteria:

- The application VM can be destroyed and recreated without losing PostgreSQL
  data, uploads, source images, video, or audio.

### Phase 5: Production Cutover

Deliverables:

- Deploy Compose stack to the production app VM.
- Point Cloudflare staging hostnames to the app VM.
- Run `tests/validation` against staging hostnames.
- Load representative image, video, and audio content.
- Verify:
  - frontend page load,
  - Strapi admin login through Cloudflare Access,
  - Strapi API health,
  - Cantaloupe `info.json` and tile responses,
  - media delivery through Cloudflare,
  - database connectivity,
  - app VM reboot recovery,
  - runner VM deployment path.
- Switch production DNS in Cloudflare.

Exit criteria:

- Production hostnames serve through Cloudflare and the recovery path has been
  tested at least once before launch.

### Phase 6: Clean Up Kubernetes Artifacts

Deliverables:

- Remove or archive OKE Terraform environments and modules.
- Remove Helm charts from active deployment docs.
- Remove External Secrets Operator manifests.
- Remove Actions Runner Controller manifests.
- Update README, platform overview, deployment plan, Cloudflare docs, and
  disaster recovery runbook.

Exit criteria:

- The repository source of truth matches the production architecture.

## Production Compose Service Requirements

The production Compose file should follow these rules:

- Use pinned image tags, never mutable `latest` for app deployment.
- Run `NODE_ENV=production` for frontend and Strapi.
- Do not run `npm ci` or build code at container startup.
- Store Strapi uploads in OCI Object Storage.
- Store IIIF source images in OCI Object Storage.
- Store video and audio in OCI Object Storage.
- Keep local Cantaloupe cache disposable.
- Put all public traffic through the proxy container.
- Bind application containers only to the internal Compose network.
- Emit logs to Docker logging or mounted log directories with rotation.
- Use restart policies and health checks.
- Document every environment variable in `production.env.example`.

## Reliability Model

This launch architecture is intentionally simple but must be recoverable.

Reliability comes from:

- managed PostgreSQL backups,
- durable Object Storage media,
- immutable container images in OCIR,
- Terraform-recreated VMs and network,
- systemd restarting Docker Compose on boot,
- Cloudflare caching and protection,
- tested restore steps.

Known tradeoff:

- One app VM is not highly available. A VM failure causes downtime until the VM
  is repaired or recreated. This is acceptable only if the rebuild process is
  tested and the launch reliability requirement allows a short recovery window.

If the required recovery time is lower than a VM rebuild window, add a second
app VM and an OCI Load Balancer after the single-VM path is working. Do not
start with that complexity unless the requirement is explicit.

## Definition Of Done For This Simplification

- ADR-007 and all launch docs point to VM + Docker Compose.
- Terraform provisions the app VM, runner VM, PostgreSQL, Object Storage,
  network, and required secrets.
- Production Compose does not include PostgreSQL or MinIO.
- CI/CD runs on the self-hosted OCI runner.
- Deployments use immutable images from OCIR.
- Cloudflare routes and protects frontend, CMS, and IIIF endpoints.
- The app VM can be rebuilt without data loss.
- Validation tests pass through Cloudflare-backed hostnames.
- Disaster recovery docs cover database restore, Object Storage recovery,
  app VM rebuild, runner VM rebuild, and Compose redeploy.
