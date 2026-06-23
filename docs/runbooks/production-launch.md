# Production Launch Runbook

Target launch date: August 1, 2026

This runbook is the operating checklist for the simplified OCI production
deployment. It prioritizes a small, reliable, maintainable launch architecture:

- one OCI application VM running Docker Compose,
- one separate OCI self-hosted GitHub Actions runner VM,
- OCI Database with PostgreSQL,
- OCI Object Storage,
- Cloudflare in front,
- no Kubernetes, OKE, Helm, Actions Runner Controller, External Secrets
  Operator, OpenSearch, multi-region deployment, or OCI Network Firewall.

## 1. OCI Prerequisites

Confirm access and tooling before provisioning:

- OCI tenancy access for the production compartment.
- OCI IAM permission to manage:
  - Compute,
  - Virtual Cloud Networks,
  - Network Security Groups and security lists,
  - Block Volumes,
  - Object Storage,
  - OCI Database with PostgreSQL,
  - Vault and KMS if `enable_vault = true`,
  - Metrics, alarms, notifications, and logging.
- Terraform installed locally or on an approved workstation.
- OCI CLI installed for Object Storage backup verification.
- SSH key pair for app VM and runner VM access.
- Cloudflare zone admin access.
- GitHub repository admin access.
- Container registry credentials for GHCR or OCIR.

Recommended OCI region:

```text
me-riyadh-1
```

Required local files that must never be committed:

```text
infrastructure/terraform/simple/terraform.tfvars
deploy/.env.prod
SSH private keys
OCI API private keys
Terraform state files
```

Before launch, decide where Terraform state will live. For production, use an
encrypted remote backend or a controlled encrypted state archive. Do not rely on
an engineer's laptop as the only state copy.

## 2. Terraform Apply Order

The simplified launch stack is a single Terraform root:

```bash
cd infrastructure/terraform/simple
cp terraform.tfvars.example terraform.tfvars
```

Fill in:

- OCI tenancy/user/fingerprint/key path,
- production compartment,
- SSH public key,
- app and runner CIDR allowlists,
- PostgreSQL password,
- bucket names,
- optional Vault settings,
- tags.

Validate before applying:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply after review:

```bash
terraform apply
terraform output
terraform output -json > /tmp/almadar-prod-terraform-outputs.json
```

The root provisions in dependency order automatically:

1. Compartment and availability-domain data lookups.
2. VCN, gateways, route tables, and subnets.
3. Security lists and NSGs.
4. Object Storage namespace lookup and buckets.
5. Optional Vault, KMS key, and secrets.
6. OCI Database with PostgreSQL.
7. App VM and app data block volume.
8. Runner VM.
9. Outputs for VM IPs, buckets, database connection metadata, and NSGs.

After apply, record:

- app VM public/private IP,
- runner VM public/private IP,
- PostgreSQL private endpoint,
- Object Storage namespace,
- bucket names,
- app and runner NSG IDs.

## 3. DNS And Cloudflare Setup

Cloudflare remains the public edge for DNS, TLS, CDN, WAF, and CMS access
control.

Create or update DNS records:

```text
PUBLIC_SITE_HOST -> app VM origin
CMS_SITE_HOST    -> app VM origin
IIIF_SITE_HOST   -> app VM origin
```

Typical hostnames:

```text
almadar.example.org
cms.almadar.example.org
iiif.almadar.example.org
```

Recommended Cloudflare settings:

- Proxy enabled for public hostnames.
- TLS mode set to Full or Full strict.
- Redirect HTTP to HTTPS.
- Cache public frontend assets.
- Cache IIIF derivatives where safe.
- Protect `CMS_SITE_HOST` with Cloudflare Access or equivalent admin control.
- Restrict app VM HTTP/HTTPS ingress to Cloudflare origin CIDRs where practical.
- Keep DNS TTL low during cutover, then raise after launch stability is proven.

Origin routing in Caddy:

- `/` routes to frontend.
- `/cms/*` routes to Strapi with `/cms` stripped.
- `/iiif/*` routes to Cantaloupe with `/iiif` stripped.
- `CMS_SITE_HOST` routes directly to Strapi.
- `IIIF_SITE_HOST` routes directly to Cantaloupe.

## 4. GitHub Self-Hosted Runner Setup

Use the runner VM created by Terraform. Do not use Actions Runner Controller.

Install on the runner VM:

- GitHub Actions runner service,
- Docker Engine,
- Docker Compose plugin,
- Node.js 22,
- Git,
- SSH client.

Register the runner with labels:

```text
self-hosted
oci
almadar
prod
```

Deployment workflows:

```text
.github/workflows/deploy-dev.yml
.github/workflows/deploy-prod.yml
```

Create GitHub environments:

```text
development
production
```

For `production`, enable required reviewers so production deployment pauses for
approval before secrets are available to the job.

Required GitHub variables:

```text
CONTAINER_REGISTRY
CONTAINER_NAMESPACE
APP_VM_USER
APP_DEPLOY_PATH
APP_ENV_FILE
```

Required GitHub secrets:

```text
REGISTRY_USERNAME
REGISTRY_PASSWORD
APP_VM_HOST
APP_VM_SSH_PRIVATE_KEY
```

For GHCR:

```text
CONTAINER_REGISTRY=ghcr.io
CONTAINER_NAMESPACE=<github-owner-or-org>
```

For OCIR:

```text
CONTAINER_REGISTRY=me-riyadh-1.ocir.io
CONTAINER_NAMESPACE=<oci-tenancy-namespace>
```

Confirm the runner can:

```bash
docker version
docker compose version
node --version
ssh <app-vm-user>@<app-vm-host> 'docker version'
```

Run the runner preflight from a repository checkout on the runner VM:

```bash
APP_VM_HOST=<app-vm-host> APP_VM_USER=<app-vm-user> \
  CONTAINER_REGISTRY=<registry> \
  REGISTRY_USERNAME=<username> \
  REGISTRY_PASSWORD=<token> \
  deploy/preflight-runner.sh
```

## 5. Object Storage Bucket Setup

Terraform creates three production buckets:

```text
Strapi uploads
IIIF source images
Backups
```

Expected names are controlled in:

```text
infrastructure/terraform/simple/terraform.tfvars
```

Verify buckets:

```bash
oci os ns get
oci os bucket list --compartment-id <compartment_ocid>
```

Upload initial assets:

- Strapi uploads should be written by Strapi through the S3-compatible API.
- IIIF source images should be loaded into the IIIF source bucket before public
  IIIF validation.
- VM deployment backups from `deploy/backup.sh` should write to the backups
  bucket.

From the app VM, validate Object Storage reachability:

```bash
curl https://objectstorage.me-riyadh-1.oraclecloud.com
```

A response such as unauthorized or not found still proves network reachability.

## 6. Strapi Environment Variables

On the app VM:

```bash
cd /opt/almadar/deploy
cp .env.prod.example .env.prod
chmod 600 .env.prod
```

Set these Strapi groups in `.env.prod`:

Application image:

```text
STRAPI_IMAGE
STRAPI_TAG
```

Strapi secrets:

```text
APP_KEYS
API_TOKEN_SALT
ADMIN_JWT_SECRET
TRANSFER_TOKEN_SALT
JWT_SECRET
ENCRYPTION_KEY
```

External OCI managed PostgreSQL:

```text
DATABASE_CLIENT=postgres
DATABASE_HOST
DATABASE_PORT=5432
DATABASE_NAME
DATABASE_USERNAME
DATABASE_PASSWORD
DATABASE_SSL=true
DATABASE_SSL_REJECT_UNAUTHORIZED=false
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10
```

OCI Object Storage S3-compatible upload provider:

```text
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
S3_REGION=me-riyadh-1
S3_ENDPOINT
S3_BUCKET
S3_ACL=private
S3_FORCE_PATH_STYLE=true
S3_ROOT_PATH=uploads
S3_SIGNED_URL_EXPIRES=900
S3_PUBLIC_BASE_URL
STRAPI_UPLOADS_CSP_SRC
```

Do not store these values in GitHub workflow files, Terraform examples, or
committed docs beyond placeholder names.

## 7. Cantaloupe Configuration

Cantaloupe uses:

```text
infrastructure/cantaloupe/cantaloupe.properties
```

The production Compose service mounts this file read-only and supplies OCI
Object Storage settings through environment variables.

Set in `.env.prod`:

```text
CANTALOUPE_IMAGE=uclalibrary/cantaloupe:5.0.7-0
CANTALOUPE_PLATFORM=linux/amd64
CANTALOUPE_CACHE_PATH=/var/lib/almadar/cantaloupe-cache
CANTALOUPE_S3SOURCE_ENDPOINT
CANTALOUPE_S3SOURCE_REGION=me-riyadh-1
CANTALOUPE_S3SOURCE_ACCESS_KEY_ID
CANTALOUPE_S3SOURCE_SECRET_KEY
CANTALOUPE_S3SOURCE_LOOKUP_STRATEGY=BasicLookupStrategy
CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_BUCKET_NAME
CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_PATH_PREFIX
CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_PATH_SUFFIX
CANTALOUPE_S3SOURCE_CHUNKING_ENABLED=true
CANTALOUPE_S3SOURCE_CHUNKING_CHUNK_SIZE=512K
CANTALOUPE_CACHE_SERVER_DERIVATIVE_ENABLED=true
CANTALOUPE_CACHE_SERVER_DERIVATIVE=FilesystemCache
```

Mount the app VM data volume so `CANTALOUPE_CACHE_PATH` has enough headroom for
the 100 GB image corpus and generated derivatives. The cache is disposable:
source images remain in Object Storage.

Validate a known image:

```bash
curl -I https://<public-host>/iiif/2/<identifier>/info.json
curl -I https://<iiif-host>/2/<identifier>/info.json
```

## 8. Deployment Steps

Before first deployment on the app VM:

```bash
sudo mkdir -p /opt/almadar/deploy
sudo chown -R <app-vm-user>:<app-vm-user> /opt/almadar
mkdir -p /var/lib/almadar/cantaloupe-cache
```

Create `.env.prod` from the example and fill in real values.

Deploy through GitHub:

1. Confirm the self-hosted runner is online.
2. Push to `develop` for dev deployment or run `deploy-dev` manually.
3. Push to `main` for production or run `deploy-prod` manually.
4. Approve the `production` GitHub Environment deployment.
5. Watch the workflow logs.

The workflow builds images, pushes them, SSHes to the app VM, and runs:

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

Manual fallback on the app VM:

```bash
cd /opt/almadar/deploy
docker compose --env-file .env.prod -f compose.prod.yml pull
docker compose --env-file .env.prod -f compose.prod.yml up -d
docker image prune -f
docker compose --env-file .env.prod -f compose.prod.yml ps
```

Run app VM preflight before cutover and after any host rebuild:

```bash
cd /opt/almadar/deploy
./preflight-app-vm.sh
```

Smoke checks:

```bash
curl -I https://<public-host>/
curl -I https://<public-host>/cms/admin
curl -I https://<public-host>/iiif/2/<known-identifier>/info.json
docker compose --env-file .env.prod -f compose.prod.yml ps
```

Run public edge preflight from a machine outside OCI after Cloudflare is
configured:

```bash
ENV_FILE=/path/to/.env.prod APP_VM_PUBLIC_IP=<app-vm-public-ip> \
  KNOWN_IIIF_IDENTIFIER=<object-key> \
  ./deploy/preflight-public.sh
```

`KNOWN_IIIF_IDENTIFIER` should be an object key known to exist in the production
IIIF source bucket.

## 9. Backup And Restore

Backups come from three sources:

| Component | Backup source |
| --- | --- |
| PostgreSQL | OCI Database with PostgreSQL automated backups |
| Media and IIIF sources | OCI Object Storage durability/versioning |
| VM deployment config | `deploy/backup.sh` archive to backups bucket |

Run a VM config backup:

```bash
cd /opt/almadar/deploy
./backup.sh
```

Verify backup object exists:

```bash
oci os object list \
  --bucket-name <backups_bucket> \
  --prefix vm-compose/
```

Restore app VM configuration:

```bash
oci os object get \
  --bucket-name <backups_bucket> \
  --name vm-compose/<archive-name>.tar.gz \
  --file /tmp/almadar-compose-restore.tar.gz

mkdir -p /tmp/almadar-restore
tar -xzf /tmp/almadar-compose-restore.tar.gz -C /tmp/almadar-restore
cp /tmp/almadar-restore/*/compose.prod.yml /opt/almadar/deploy/
cp /tmp/almadar-restore/*/Caddyfile /opt/almadar/deploy/
cp /tmp/almadar-restore/*/env.prod /opt/almadar/deploy/.env.prod
chmod 600 /opt/almadar/deploy/.env.prod
```

Restore PostgreSQL from OCI managed backup using the approved OCI console or
CLI procedure, then update `DATABASE_HOST` in `.env.prod` if the endpoint
changes.

Restore media by recovering Object Storage objects or versions. Do not restore
media to VM-local disk except for temporary transfer work.

## 10. Monitoring Checks

Before launch, create alerts for:

- app VM status,
- runner VM status,
- app VM CPU,
- app VM memory if collected,
- app VM boot/data volume utilization,
- PostgreSQL CPU,
- PostgreSQL storage,
- PostgreSQL backup failure,
- public endpoint availability,
- Cloudflare origin errors,
- Object Storage access errors if available through logs.

Useful manual checks:

```bash
ssh <app-vm-user>@<app-vm-host>
docker compose --env-file /opt/almadar/deploy/.env.prod -f /opt/almadar/deploy/compose.prod.yml ps
docker system df
df -h
free -h
curl -I http://127.0.0.1/healthz -H "Host: <public-host>"
```

Check PostgreSQL logs and metrics in OCI. OCI Database with PostgreSQL exposes
managed service monitoring and can integrate with OCI Logging for database
system logs.

Check Cloudflare:

- DNS proxied status.
- WAF events.
- Cache hit ratio for public assets and IIIF derivatives.
- 5xx responses from origin.

## 11. Rollback Procedure

Rollback uses the previous known-good image tags. The app data remains in OCI
PostgreSQL and Object Storage; do not roll those back unless the incident is a
data migration problem and leadership approves.

Find previous tags:

- GitHub Actions deployment history.
- Container registry tags.
- `/opt/almadar/deploy/.env.prod` backup archive.

On the app VM:

```bash
cd /opt/almadar/deploy
cp .env.prod ".env.prod.before-rollback-$(date -u +%Y%m%dT%H%M%SZ)"

vi .env.prod
# Set FRONTEND_TAG and STRAPI_TAG to known-good tags.

docker compose --env-file .env.prod -f compose.prod.yml pull
docker compose --env-file .env.prod -f compose.prod.yml up -d
docker image prune -f
docker compose --env-file .env.prod -f compose.prod.yml ps
```

Verify:

```bash
curl -I https://<public-host>/
curl -I https://<public-host>/cms/admin
curl -I https://<public-host>/iiif/2/<known-identifier>/info.json
```

If rollback fails because the app VM is unhealthy:

1. Stop changing DNS.
2. Recreate the app VM from Terraform.
3. Restore `/opt/almadar/deploy` from the backups bucket.
4. Run Compose with known-good tags.
5. Update Cloudflare DNS only if the origin IP changed.

## 12. Post-Launch Hardening Tasks

Prioritize these after August 1:

- Move Terraform state to an encrypted remote backend if not already done.
- Restrict app VM HTTP/HTTPS ingress to Cloudflare origin CIDRs.
- Restrict SSH ingress to runner VM and approved admin/VPN CIDRs.
- Add OCI alarms and notification topics for VM, PostgreSQL, and storage.
- Add Cloudflare cache and WAF rules as code where practical.
- Add a tested app VM rebuild drill.
- Add a tested PostgreSQL restore drill.
- Add a tested Object Storage object-version restore drill.
- Add Docker log rotation and host patching schedule.
- Add uptime checks from outside OCI.
- Add a second app VM and load balancer only if recovery-time requirements
  justify the extra moving parts.
- Reassess Kubernetes only after launch if measured traffic, staffing, or
  availability requirements make it worth the operational cost.
