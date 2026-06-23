# Pre-Implementation Architecture Review

Date: 2026-06-21

Updated: 2026-06-23 to reflect the August 1 launch decision to defer Actions
Runner Controller and use GitHub-hosted image builds plus manual Helm deployment
from an approved workstation or OCI Cloud Shell.

Status: Recommended actions before production implementation

## Scope

This review covers the proposed OCI architecture for:

- Next.js frontend
- Strapi CMS
- Cantaloupe IIIF image server
- OCI Object Storage
- OCI Database with PostgreSQL managed service
- Cloudflare
- GitHub Actions image builds, with Actions Runner Controller deferred

The assumptions are a small cultural heritage team, limited DevOps staff, a
nonprofit-sensitive infrastructure budget, and a 5-10 year project lifespan.

## Executive Assessment

The proposed architecture is directionally sound for the platform scale. OCI
Object Storage as canonical media storage, OCI Database with PostgreSQL,
stateless
application containers, Cloudflare at the edge, and deferring OpenSearch are all
appropriate choices.

The primary risk is operational concentration. A single OKE cluster is planned
to run `dev`, `test`, `prod`, application workloads, and Cantaloupe. This is
cost-efficient, but OKE should not also become the required control plane for
deployment before the August 1 launch.

This tradeoff is acceptable only if the implementation adds guardrails before
production launch.

## Highest-Risk Items

### CI/CD Must Not Depend On The Cluster It Deploys

Actions Runner Controller would run inside OKE. If OKE is degraded, deleted, or
unreachable, any ARC-dependent deployment path is also degraded.

Recommendations:

- Defer ARC from the August 1 launch.
- Use GitHub-hosted runners for CI and immutable image builds.
- Deploy with Helm from an approved workstation or OCI Cloud Shell.
- Add ARC later only if private automated deployment is a confirmed
  requirement.
- Keep the manual Helm deployment path documented and tested.

### Organization-Scoped Self-Hosted Runners Are High Privilege

The planned ARC scale set is organization-scoped and uses Docker-in-Docker. This
is deferred from the August 1 launch because it expands the blast radius of
compromised workflows.

Recommendations:

- Restrict which repositories can target the OCI runner label.
- Do not run untrusted pull request code from forks on OCI self-hosted runners.
- Require least-privilege `GITHUB_TOKEN` permissions in workflows.
- Pin third-party GitHub Actions to full commit SHAs.
- Start with a lower `maxRunners` value until real concurrency is measured.
- Prefer a dedicated runner node pool with taints and tolerations if budget
  allows.

### Single OKE Cluster Requires Strong Namespace Guardrails

The single-cluster design is appropriate for cost control, but production
isolation depends on Kubernetes policy rather than physical cluster separation.

Recommendations:

- Add `ResourceQuota` and `LimitRange` per namespace.
- Add default-deny NetworkPolicies and allow only required service paths.
- Enforce Pod Security Admission labels for `dev`, `test`, and `prod`.
- Use app-specific service accounts instead of broad namespace defaults.
- Keep production release permissions separate from dev/test permissions.
- Revisit a separate production cluster only if compliance, security, or
  incident history justifies the added cost.

### Production Images Must Be Immutable

Production pods should not build application code at startup. Builds should
happen in CI, with versioned artifacts pushed to OCIR.

Recommendations:

- Build Next.js and Strapi images in GitHub Actions.
- Push immutable tags or deploy by image digest.
- Remove `npm ci` and build steps from production pod startup.
- Enable Next.js standalone output for containerized self-hosting.
- Keep runtime images small and production-only.

### PostgreSQL Cost May Dominate Monthly Spend

Separate OCI Database with PostgreSQL managed DB systems for `dev`, `test`, and
`prod` improve isolation but may be expensive relative to the expected workload.

Recommendations:

- Keep production PostgreSQL isolated.
- Reevaluate whether `dev` and `test` need separate managed DB systems.
- Consider smaller non-production shapes where OCI supports them.
- Consider scheduled shutdown or reduced retention for non-production systems.
- Consider one non-production DB system with separate databases if the risk is
  acceptable.
- Measure Strapi workload before committing to larger shapes.

## Security Risks

### Database TLS

Production Strapi should use TLS when connecting to OCI Database with
PostgreSQL.

Recommendations:

- Set `DATABASE_SSL=true` for production.
- Prefer certificate verification where OCI Database with PostgreSQL support and
  operational procedures allow it.
- Avoid leaving production with `DATABASE_SSL_REJECT_UNAUTHORIZED=false` unless
  the exception is documented and revisited.

### Object Storage Access

The object-storage model must distinguish public media delivery from private
source and administrative assets.

Recommendations:

- Do not rely on default `public-read` behavior without bucket-specific review.
- Keep IIIF source/master buckets private unless there is an explicit public
  access requirement.
- Serve public media through Cloudflare and application-controlled URLs where
  possible.
- Use separate credentials per environment and workload.
- Scope object permissions to the minimum required bucket and action.

### Origin Protection

Cloudflare provides WAF, TLS, CDN, and Access controls, but those controls can
be bypassed if the OCI origin accepts direct public traffic.

Recommendations:

- Use Cloudflare Full (strict) TLS.
- Add Cloudflare Authenticated Origin Pulls or equivalent mTLS before
  production.
- Avoid manual allowlists of Cloudflare IP ranges unless there is automation to
  keep ranges current.
- Ensure Strapi admin is protected by Cloudflare Access.
- Keep Strapi API cache bypass rules conservative until response caching is
  explicitly designed.

### Kubernetes Secret And Service Account Boundaries

External Secrets is the right pattern, but Kubernetes blast radius still depends
on service account and namespace boundaries.

Recommendations:

- Disable service account token automounting where pods do not need Kubernetes
  API access.
- Use separate ExternalSecrets per environment.
- Review generated Kubernetes Secrets for only the keys each workload needs.
- Avoid sharing broad `almadar-secrets` payloads with every application if
  narrower secrets are practical.

## Operational Risks

### Cantaloupe Cache And Scaling

Cantaloupe production currently targets multiple replicas, while filesystem
cache persistence can create scheduling and consistency concerns.

Recommendations:

- Prefer per-pod ephemeral derivative cache plus Cloudflare caching unless a
  shared cache is proven necessary.
- If using persistent cache, explicitly document PVC access mode behavior with
  multiple replicas.
- Keep Cloudflare IIIF cache keys path- and query-aware.
- Add a documented purge process for replaced source images.

### Recovery Must Be Practiced

The repository includes a disaster recovery runbook, but recovery is only real
after it has been tested.

Recommendations:

- Run a quarterly recovery exercise.
- Test PostgreSQL restore into a non-production environment.
- Test object-storage recovery for IIIF and Strapi buckets.
- Test OKE rebuild and External Secrets recovery.
- Test redeployment using known-good OCIR image tags.
- Record recovery time, gaps, and follow-up tasks after every exercise.

### Cloudflare Must Become Reproducible

Cloudflare is currently documented as operational procedure. That is a good
start, but manual dashboard configuration can drift over a 5-10 year lifespan.

Recommendations:

- Manage Cloudflare DNS records as code.
- Manage cache rules, WAF custom rules, and Access applications as code where
  provider support allows.
- Keep manual emergency changes documented immediately after the incident.
- Add Cloudflare configuration verification to smoke tests.

## Cost Risks

### OKE Baseline Capacity

The planned OKE node pool starts with three worker nodes. That may be reasonable
for availability, but it is a fixed monthly floor.

Recommendations:

- Measure actual CPU and memory usage after the first realistic test content
  load.
- Keep requests and limits explicit for every workload.
- Isolate bursty ARC runners from steady production workloads if possible.
- Avoid always-on idle runners.

### Non-Production Environments

Always-on `dev` and `test` infrastructure can quietly consume production-like
budget.

Recommendations:

- Define which non-production services must be always on.
- Scale down non-production app workloads outside active work periods if
  acceptable.
- Use lower backup retention for non-production databases and buckets.
- Review monthly OCI cost reports as an operational ritual.

### Cloudflare Feature Tier Drift

Cloudflare features can be adopted incrementally, but plan-specific features
may create unplanned recurring cost.

Recommendations:

- Record which Cloudflare plan is assumed.
- Avoid relying on paid-only features without budget approval.
- Prefer simple cache, WAF, TLS, and Access controls before advanced edge
  features.

## Long-Term Maintenance Concerns

### Kubernetes Upgrade Ownership

OKE and Kubernetes versions will require regular upgrade work over a 5-10 year
lifespan.

Recommendations:

- Maintain a documented upgrade calendar.
- Test cluster upgrades in non-production first.
- Keep Helm charts compatible with supported Kubernetes APIs.
- Avoid installing operators unless their lifecycle owner is clear.

### Dependency And Image Hygiene

Long-running cultural heritage platforms often fail from slow dependency drift,
not immediate scale problems.

Recommendations:

- Pin base images intentionally.
- Track Strapi, Next.js, Node.js, Cantaloupe, PostgreSQL, and ARC upgrade
  windows.
- Run dependency and image vulnerability scans in CI.
- Keep rollback instructions tied to immutable image tags.

### Documentation As Source Of Truth

The repository already states that no platform behavior should exist only in
external systems. This should remain a launch criterion.

Recommendations:

- Add ADRs for any major deviation from this review.
- Keep runbooks actionable for a future engineer with no project history.
- Document operational ownership for OCI, Cloudflare, GitHub, and Kubernetes.

## Recommended Pre-Launch Checklist

- Production deployments use immutable OCIR images.
- Next.js uses standalone output for container deployment.
- Strapi production database connections use TLS.
- ARC runner use is restricted and documented.
- A break-glass deployment path exists without ARC.
- Namespace quotas, limits, NetworkPolicies, and Pod Security Admission are in
  place.
- Cloudflare origin protection uses Full (strict) TLS and mTLS or Authenticated
  Origin Pulls.
- Cloudflare DNS, WAF, cache, and Access settings are reproducible or have an
  explicit IaC backlog item with owner and date.
- PostgreSQL sizing and non-production cost strategy are approved.
- Object Storage bucket access, versioning, lifecycle, and restore behavior are
  tested.
- Disaster recovery has been exercised at least once before production launch.

## Architecture Position

Proceed with the proposed architecture after the pre-launch hardening work
above. Do not add OpenSearch, service mesh, distributed caching, or additional
clusters unless there is a documented requirement or measured operational need.

The guiding principle should remain: boring, reproducible infrastructure that a
small team can understand, recover, and afford over the full project lifespan.
