# Production Docker Compose Deployment

This directory is the production VM deployment bundle for the simplified launch
architecture. It runs only the application containers:

- Caddy reverse proxy,
- Next.js frontend,
- Strapi CMS,
- Cantaloupe IIIF server.

PostgreSQL is external OCI managed PostgreSQL. Strapi uploads and IIIF source
images live in OCI Object Storage. The VM-local disk is used only for Docker
data, logs, and the Cantaloupe derivative cache.

## Files

```text
deploy/
  compose.prod.yml
  Caddyfile
  .env.prod.example
  deploy.sh
  backup.sh
  README.md
```

## First Setup

Copy the example environment file on the production VM:

```bash
cp .env.prod.example .env.prod
chmod 600 .env.prod
```

Fill in real image tags, OCI PostgreSQL values, Strapi secrets, Object Storage
credentials, bucket names, and hostnames.

Create a large enough data volume on the VM before launch. The Terraform simple
stack provisions a separate app data volume; mount it for Docker data and
`CANTALOUPE_CACHE_PATH`, for example `/var/lib/almadar/cantaloupe-cache`. The
Cantaloupe cache path should have headroom for the 100 GB source-image corpus
and generated derivatives.

## Deploy

```bash
./deploy.sh
```

The script pulls immutable image tags, starts the stack, waits for health
checks, and prints service status.

## Routes

Caddy routes:

- `/` on `PUBLIC_SITE_HOST` to the frontend,
- `/cms/*` on `PUBLIC_SITE_HOST` to Strapi, with the `/cms` prefix stripped,
- `/iiif/*` on `PUBLIC_SITE_HOST` to Cantaloupe, with the `/iiif` prefix
  stripped,
- all traffic on `CMS_SITE_HOST` to Strapi,
- all traffic on `IIIF_SITE_HOST` to Cantaloupe.

Use Cloudflare in front of the VM for DNS, TLS policy, WAF, CDN, and CMS access
controls.

## Backups

```bash
./backup.sh
```

This backs up the Compose file, Caddyfile, production environment file, and
current Docker container/volume inventory. It uploads the archive to the OCI
Object Storage backups bucket when the OCI CLI and `BACKUP_BUCKET` are
configured.

Database backups are handled by OCI managed PostgreSQL. Strapi uploads and IIIF
sources are already durable in OCI Object Storage.

## Operations

Useful commands:

```bash
docker compose --env-file .env.prod -f compose.prod.yml ps
docker compose --env-file .env.prod -f compose.prod.yml logs -f proxy
docker compose --env-file .env.prod -f compose.prod.yml logs -f strapi
docker compose --env-file .env.prod -f compose.prod.yml restart frontend
docker compose --env-file .env.prod -f compose.prod.yml pull
```

Do not add PostgreSQL, MinIO, OKE, Helm, Actions Runner Controller, or External
Secrets Operator to this production Compose stack.
