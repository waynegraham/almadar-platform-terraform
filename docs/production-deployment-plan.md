# Production Deployment Plan

Date: 2026-06-23

Target launch date: August 1, 2026

## Decision

Use a simplified OCI VM + Docker Compose production deployment for the August 1
launch.

OKE, Helm, External Secrets Operator, and Actions Runner Controller are deferred.
The launch architecture uses managed OCI data services, Cloudflare at the edge,
one application VM, and one separate self-hosted GitHub Actions runner VM.

## Production Architecture

The August 1 production system should use:

- one primary OCI region, `me-riyadh-1`,
- one OCI Compute VM for the application runtime,
- Docker Compose on the application VM,
- Caddy or nginx as the public reverse proxy container,
- Next.js frontend container,
- Strapi CMS container,
- Cantaloupe IIIF container,
- one separate OCI Compute VM for the self-hosted GitHub Actions runner,
- OCI Database with PostgreSQL managed service for Strapi,
- OCI Object Storage for Strapi uploads, IIIF source images, video, and audio,
- OCIR for immutable frontend and Strapi images,
- Cloudflare in front of public frontend, CMS/API, and IIIF hostnames,
- local VM disk only for Docker data, logs, and Cantaloupe cache.

## What Is Deferred

These items are intentionally deferred until after launch:

- OKE/Kubernetes,
- Helm production deployment,
- External Secrets Operator,
- Actions Runner Controller,
- active Jeddah deployment,
- multiple application VMs behind an OCI Load Balancer,
- OpenSearch,
- OCI Network Firewall,
- Private Vault or HSM-backed keys,
- large persistent Cantaloupe cache,
- separate managed PostgreSQL DB systems for every non-production environment.

## Deployment Workflow

Image build workflow:

```text
OCI self-hosted GitHub Actions runner
  -> run app checks
  -> build immutable frontend and Strapi images
  -> push images to OCIR
```

Deployment workflow:

```text
OCI self-hosted GitHub Actions runner
  -> SSH to application VM
  -> select approved image tags
  -> docker compose pull
  -> run Strapi migrations
  -> docker compose up -d
  -> run smoke tests through Cloudflare or origin staging hostnames
```

## Required Production Files

Add these files before launch:

```text
deploy/
  compose/
    production.compose.yml
    production.env.example
    caddy/Caddyfile
    systemd/almadar-compose.service
    scripts/deploy.sh
    scripts/run-strapi-migrations.sh
  runner/
    install-runner.sh
    runner.env.example
    systemd/github-runner.service
```

Production Compose must not include PostgreSQL or MinIO. Those are local
development services only.

## Production Compose Requirements

The production Compose stack should include:

- `proxy`: Caddy or nginx, the only public HTTP/HTTPS entrypoint,
- `frontend`: immutable OCIR image from `apps/frontend/Dockerfile`,
- `strapi`: immutable OCIR image from `apps/strapi/Dockerfile`,
- `cantaloupe`: pinned Cantaloupe image and repository Cantaloupe config.

The stack should:

- bind app containers only to the internal Compose network,
- use pinned image tags,
- run `NODE_ENV=production`,
- avoid `npm ci` or source builds at startup,
- use OCI Database with PostgreSQL,
- use OCI Object Storage for Strapi uploads and source media,
- keep local Cantaloupe cache disposable,
- include container health checks,
- restart automatically after VM reboot,
- rotate logs or use Docker logging limits.

## Environment Variables

`deploy/compose/production.env.example` should document, at minimum:

```bash
FRONTEND_IMAGE=
FRONTEND_TAG=
STRAPI_IMAGE=
STRAPI_TAG=
NEXT_PUBLIC_STRAPI_URL=
STRAPI_INTERNAL_URL=http://strapi:1337

DATABASE_CLIENT=postgres
DATABASE_HOST=
DATABASE_PORT=5432
DATABASE_NAME=
DATABASE_USERNAME=
DATABASE_PASSWORD=
DATABASE_SSL=true

S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
S3_REGION=me-riyadh-1
S3_ENDPOINT=
S3_BUCKET=strapi-prod
S3_FORCE_PATH_STYLE=true
S3_PUBLIC_BASE_URL=

IIIF_BUCKET=iiif-prod
CANTALOUPE_S3_PREFIX=
CANTALOUPE_CACHE_MAX_SIZE=

APP_KEYS=
API_TOKEN_SALT=
ADMIN_JWT_SECRET=
TRANSFER_TOKEN_SALT=
JWT_SECRET=
ENCRYPTION_KEY=
```

The example file must not contain real secrets.

## Manual Deployment Shape

The deployment script should execute this basic sequence on the application VM:

```bash
cd /opt/almadar/deploy/compose
docker compose --env-file /etc/almadar/production.env -f production.compose.yml pull
docker compose --env-file /etc/almadar/production.env -f production.compose.yml run --rm strapi npm run migrate
docker compose --env-file /etc/almadar/production.env -f production.compose.yml up -d
docker compose --env-file /etc/almadar/production.env -f production.compose.yml ps
```

If Strapi does not expose a reliable migration command for the current schema
workflow, replace the migration step with the repository's documented Strapi
database migration procedure before production launch.

## Infrastructure Provisioning Order

1. Provision the primary VCN, subnets, gateways, route tables, and NSGs.
2. Provision OCI Object Storage buckets for production media.
3. Provision OCI Database with PostgreSQL.
4. Provision OCIR repositories with immutable image tags where practical.
5. Provision the application VM.
6. Provision the runner VM.
7. Install Docker/Compose and the systemd Compose service on the app VM.
8. Install and register the GitHub Actions runner on the runner VM.
9. Configure Cloudflare staging hostnames.
10. Deploy the Compose stack.
11. Run validation tests.
12. Switch production hostnames.

## Production Readiness Checklist

- Frontend image builds on the OCI self-hosted runner.
- Strapi image builds on the OCI self-hosted runner.
- Production deployment does not require GitHub-hosted runners.
- Application VM boots and starts Compose automatically.
- Production Compose does not include PostgreSQL or MinIO.
- OCI Database with PostgreSQL is reachable from Strapi with TLS enabled.
- `iiif-prod` contains production IIIF source images.
- Production video and audio objects are in OCI Object Storage.
- Strapi uploads write to OCI Object Storage.
- Cantaloupe can read from `iiif-prod`.
- Cloudflare routes public hostnames to the application VM proxy.
- Strapi admin is protected by Cloudflare Access or equivalent controls.
- Cantaloupe cache can be deleted without data loss.
- App VM rebuild has been tested from Terraform and OCIR images.
- Runner VM rebuild or re-registration has been documented.
- Disaster recovery runbook matches the VM + Compose launch architecture.
- Validation tests pass against Cloudflare-backed staging or production
  hostnames.

## Post-Launch Hardening

After August 1, decide whether to add:

- a second application VM and OCI Load Balancer,
- automated VM patching windows,
- Cloudflare DNS/cache/WAF configuration as Terraform,
- deeper OCI monitoring alarms,
- restore drills with measured recovery time,
- OKE only if scale or availability requirements justify it.
