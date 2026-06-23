# almadar-platform

`almadar-platform` is the infrastructure and application monorepo for the
AlMadar Digital platform. It contains the local development stack, production
deployment assets, Terraform infrastructure, CI/CD workflows, and operating
documentation needed to recreate the platform from source control.

The platform currently consists of:

- a Next.js frontend,
- a Strapi CMS,
- a Cantaloupe IIIF image server,
- PostgreSQL for CMS data,
- S3-compatible object storage for Strapi uploads and IIIF source images,
- Cloudflare for DNS, TLS, CDN, WAF, and CMS access controls.

## Current Project Status

The current production launch path is the simplified OCI VM deployment
documented in [docs/runbooks/production-launch.md](docs/runbooks/production-launch.md).

The production architecture is:

- one OCI application VM running Docker Compose,
- one separate OCI self-hosted GitHub Actions runner VM,
- OCI Database with PostgreSQL,
- OCI Object Storage buckets for uploads, IIIF source images, and backups,
- Caddy as the production reverse proxy,
- Cloudflare in front of the public site, CMS, and IIIF endpoints.

Kubernetes, OKE, Helm production deployment, External Secrets Operator, Actions
Runner Controller, OpenSearch, multi-region deployment, and OCI Network Firewall
are deferred. Their files remain in the repository as future reference material,
not as the August 2026 launch path.

## Key Documentation

- [Platform overview](docs/platform-overview.md): non-technical and IT-oriented architecture summary.
- [Production launch runbook](docs/runbooks/production-launch.md): launch checklist and operating sequence.
- [Production deployment plan](docs/production-deployment-plan.md): selected deployment architecture and rationale.
- [Production deploy bundle](deploy/README.md): VM Compose deployment, preflight checks, and backup commands.
- [Simple Terraform stack](infrastructure/terraform/simple/README.md): OCI launch infrastructure.
- [Disaster recovery runbook](docs/runbooks/disaster-recovery.md): recovery procedures.
- [Cloudflare documentation](docs/cloudflare.md): Cloudflare responsibilities and configuration notes.
- [Architecture decisions](docs/adr/README.md): ADR index.

## Repository Layout

```text
apps/
  frontend/                  Next.js application
  strapi/                    Strapi CMS application

deploy/                      Production VM Docker Compose deployment bundle

infrastructure/
  cantaloupe/                Cantaloupe IIIF configuration
  minio/                     Local MinIO bucket initialization
  postgresql/                Local PostgreSQL initialization
  terraform/
    simple/                  Current OCI production launch Terraform root
    future/                  Preserved future Kubernetes and split-stack Terraform
  helm/                      Deferred Helm charts and values
  k3d/                       Deferred local Kubernetes assets
  kubernetes/                Deferred Kubernetes manifests

docs/                        Architecture, runbooks, setup docs, ADRs
tests/validation/            Deployment validation tests
.github/workflows/           CI and deployment workflows
```

## Prerequisites

For local application development:

- Docker Desktop or compatible Docker Engine,
- Docker Compose v2,
- Node.js 20 or newer,
- npm.

For production infrastructure and deployment:

- Terraform,
- OCI CLI and OCI account credentials,
- SSH key pair for the app VM and runner VM,
- GitHub repository admin access,
- Cloudflare zone admin access,
- container registry credentials for GHCR or OCIR.

## Local Quick Start

Create a local environment file:

```bash
cp .env.example .env
```

Review `.env` before starting services. The example values are usable for local
development, but the placeholder secrets must not be used outside a developer
machine.

Start the full local stack:

```bash
docker compose up -d
```

Check service health:

```bash
docker compose ps
```

Local services:

- Frontend: `http://localhost:3000`
- Strapi admin: `http://localhost:1337/admin`
- PostgreSQL: `localhost:5432`
- MinIO API: `http://localhost:9000`
- MinIO console: `http://localhost:9001`
- Cantaloupe IIIF: `http://localhost:8182`

MinIO is initialized with:

- `iiif-dev` for Cantaloupe source images,
- `strapi-dev` for Strapi media uploads.

The application code uses S3-compatible APIs. Local development points those
APIs at MinIO; production points the same style of configuration at OCI Object
Storage.

## Make Targets

```bash
make bootstrap    # Install frontend and Strapi dependencies locally
make local-up     # Start Docker Compose services
make local-down   # Stop Docker Compose services
make test         # Run app test scripts where defined
make lint         # Run app lint scripts where defined
```

The Compose stack runs `npm ci` inside the app containers. `make bootstrap` is
only needed when running app commands directly on the host.

## Local Development

Run everything in Docker:

```bash
docker compose up -d
docker compose logs -f frontend strapi
```

Run the frontend directly on the host:

```bash
cd apps/frontend
npm install
npm run dev
```

Run Strapi directly on the host:

```bash
cd apps/strapi
npm install
npm run develop
```

When running apps on the host, keep Docker services running for PostgreSQL,
MinIO, and Cantaloupe.

If ports are already in use, either stop the conflicting service or change the
relevant port in `.env` before starting Compose:

```env
FRONTEND_PORT=3000
STRAPI_PORT=1337
POSTGRES_PORT=5432
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
CANTALOUPE_PORT=8182
```

## Production Infrastructure

The current production Terraform root is:

```text
infrastructure/terraform/simple/
```

It provisions:

- VCN, public app subnet, public runner subnet, and private database subnet,
- security lists and Network Security Groups,
- application VM for Docker Compose,
- separate GitHub self-hosted runner VM,
- OCI Database with PostgreSQL,
- Object Storage buckets for Strapi uploads, IIIF source images, and backups,
- optional OCI Vault, KMS key, and secrets,
- outputs needed by deployment and operations.

Provisioning flow:

```bash
cd infrastructure/terraform/simple
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output
```

Do not commit `terraform.tfvars`, Terraform state files, generated SSH private
keys, OCI API private keys, production environment files, or generated
kubeconfig files.

If `enable_vault = true`, Terraform state contains secret payloads used to
create OCI Vault secret versions. Use an encrypted remote backend before using
Vault-managed secrets in a shared environment.

## Production Deployment

Production deployment assets live in:

```text
deploy/
```

The production Compose stack runs only:

- `proxy`: Caddy reverse proxy,
- `frontend`: immutable frontend image,
- `strapi`: immutable Strapi image,
- `cantaloupe`: IIIF image server.

Production Compose does not run PostgreSQL or MinIO. PostgreSQL is OCI Database
with PostgreSQL, and media objects live in OCI Object Storage.

Deployment and preflight entry points:

```bash
cd deploy
./preflight-app-vm.sh
./deploy.sh
./backup.sh
```

Public edge validation is run from outside OCI after Cloudflare DNS is
configured:

```bash
ENV_FILE=/path/to/.env.prod APP_VM_PUBLIC_IP=<app-vm-public-ip> \
  KNOWN_IIIF_IDENTIFIER=<object-key> \
  ./deploy/preflight-public.sh
```

See [deploy/README.md](deploy/README.md) for the complete production VM
operating procedure.

## Object Storage

The stack uses S3-compatible environment variables:

```env
S3_ACCESS_KEY_ID=almadar
S3_SECRET_ACCESS_KEY=change-me-minio-password
S3_REGION=us-east-1
S3_ENDPOINT=http://minio:9000
S3_FORCE_PATH_STYLE=true
```

Strapi uploads use:

```env
S3_BUCKET=strapi-dev
S3_ROOT_PATH=uploads
S3_PUBLIC_BASE_URL=http://localhost:9000/strapi-dev
STRAPI_UPLOADS_CSP_SRC=http://localhost:9000
```

Cantaloupe reads IIIF source images from:

```env
IIIF_BUCKET=iiif-dev
CANTALOUPE_S3_PREFIX=
CANTALOUPE_S3_SUFFIX=
```

For OCI Object Storage, keep the same application code and change environment
values:

```env
S3_ENDPOINT=https://<namespace>.compat.objectstorage.<oci-region>.oraclecloud.com
S3_REGION=<oci-region>
S3_ACCESS_KEY_ID=<oci-customer-secret-key-access-key>
S3_SECRET_ACCESS_KEY=<oci-customer-secret-key-secret>
S3_FORCE_PATH_STYLE=true
```

## Strapi Upload Checks

Strapi is configured in `apps/strapi/config/plugins.ts` to use
`@strapi/provider-upload-aws-s3`.

To verify uploads locally:

1. Open `http://localhost:1337/admin`.
2. Create the first admin user if needed.
3. Upload a file in the Media Library.
4. Confirm the object appears in MinIO under `strapi-dev/uploads/`.

List buckets:

```bash
docker run --rm --network almadar-local --entrypoint sh minio/mc:latest \
  -c 'mc alias set local http://minio:9000 almadar change-me-minio-password >/dev/null && mc ls local'
```

List Strapi uploads:

```bash
docker run --rm --network almadar-local --entrypoint sh minio/mc:latest \
  -c 'mc alias set local http://minio:9000 almadar change-me-minio-password >/dev/null && mc ls --recursive local/strapi-dev'
```

## Cantaloupe IIIF

Cantaloupe is configured in
`infrastructure/cantaloupe/cantaloupe.properties` and reads source images via
`S3Source` from `iiif-dev`.

Example IIIF endpoints:

```text
http://localhost:8182/iiif/2/<object-key>/info.json
http://localhost:8182/iiif/2/<object-key>/full/256,/0/default.jpg
http://localhost:8182/iiif/2/<object-key>/0,0,512,512/256,/0/default.jpg
```

Upload a local image into the IIIF bucket for manual testing:

```bash
docker run --rm --network almadar-local \
  -v "$PWD:/workspace" \
  --entrypoint sh minio/mc:latest \
  -c 'mc alias set local http://minio:9000 almadar change-me-minio-password >/dev/null && mc cp /workspace/path/to/image.jpg local/iiif-dev/image.jpg'
```

Then verify:

```text
http://localhost:8182/iiif/2/image.jpg/info.json
http://localhost:8182/iiif/2/image.jpg/full/256,/0/default.jpg
```

## Validation

Basic local checks:

```bash
docker compose config --quiet
make lint
make test
```

Deployment validation tests live under `tests/validation`:

```bash
cd tests/validation
npm ci
npm test
npm run typecheck
```

Local defaults target Docker Compose and k3d ports. Production validation must
set explicit endpoint, database, object storage, and Strapi upload token
environment variables as documented in
[tests/validation/README.md](tests/validation/README.md).

## Deferred Kubernetes Assets

Kubernetes, k3d, and Helm are not the production launch path. Keep them for
future migration validation or experiments.

If validating k3d locally, stop Docker Compose first because k3d binds the same
local ports:

```bash
docker compose down
./infrastructure/k3d/bootstrap.sh
kubectl -n dev get pods
./infrastructure/k3d/delete.sh
```

Helm charts live under `infrastructure/helm/` and have separate values overlays
for `dev`, `test`, and `prod`.

```bash
helm lint infrastructure/helm/frontend
helm lint infrastructure/helm/frontend -f infrastructure/helm/frontend/values-dev.yaml
helm lint infrastructure/helm/strapi
helm lint infrastructure/helm/strapi -f infrastructure/helm/strapi/values-dev.yaml
helm lint infrastructure/helm/cantaloupe
helm lint infrastructure/helm/cantaloupe -f infrastructure/helm/cantaloupe/values-dev.yaml
```

Render a chart locally before installing it:

```bash
helm template almadar-dev-frontend infrastructure/helm/frontend \
  -f infrastructure/helm/frontend/values-dev.yaml \
  --namespace dev
```

## Useful Commands

View logs:

```bash
docker compose logs -f
```

Restart one local service:

```bash
docker compose up -d --force-recreate strapi
```

Stop local services:

```bash
docker compose down
```

Stop local services and remove local volumes:

```bash
docker compose down -v
```

Rerun MinIO bucket initialization:

```bash
docker compose up -d --force-recreate minio-init
```

## Troubleshooting

If Strapi or the frontend takes time on first boot, check logs. The first
container start installs dependencies into named Docker volumes.

```bash
docker compose logs -f strapi frontend
```

If MinIO buckets are missing, rerun the bucket initializer:

```bash
docker compose up -d --force-recreate minio-init
```

If Cantaloupe returns `404` for an image, confirm the object key exists in
`iiif-dev` and matches the URL identifier exactly.
