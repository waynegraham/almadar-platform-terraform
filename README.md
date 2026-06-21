# almadar-platform

`almadar-platform` is the monorepo for the Almadar platform. It includes a Next.js frontend, a Strapi CMS, local object storage, PostgreSQL, and a Cantaloupe IIIF image server.

## What Runs Locally

`docker compose up` starts:

- Frontend: Next.js on `http://localhost:3000`
- CMS: Strapi on `http://localhost:1337/admin`
- Database: PostgreSQL 17 on `localhost:5432`
- Object storage: MinIO API on `http://localhost:9000`
- MinIO console: `http://localhost:9001`
- IIIF image server: Cantaloupe on `http://localhost:8182`

MinIO is initialized with:

- `iiif-dev` for Cantaloupe source images
- `strapi-dev` for Strapi media uploads

The application code uses S3-compatible APIs. Local development points those APIs at MinIO; production can point the same environment variables at OCI Object Storage.

## Repository Layout

```text
apps/
  frontend/                  Next.js application
  strapi/                    Strapi CMS application

infrastructure/
  cantaloupe/                Cantaloupe IIIF configuration
  minio/                     MinIO bucket initialization
  postgresql/                PostgreSQL initialization
  terraform/                 Terraform infrastructure
  kubernetes/                Shared Kubernetes manifests
  helm/                      Helm charts and values
  k3d/                       Local Kubernetes assets

docs/                        Project documentation
.github/workflows/           GitHub Actions workflows
```

## Prerequisites

- Docker Desktop or a compatible Docker Engine
- Docker Compose v2
- Node.js 20 or newer
- npm

Optional for infrastructure work:

- Terraform
- kubectl
- Helm
- k3d
- OCI account credentials with permission to manage networking, OKE, Object Storage, PostgreSQL, Vault, KMS, and IAM policies

## Quick Start

Create a local environment file:

```bash
cp .env.example .env
```

Review `.env` before starting services. The example file is usable for local development, but its placeholder secrets should not be used outside a developer machine.

Start the full local stack:

```bash
docker compose up -d
```

Check service health:

```bash
docker compose ps
```

Open the main services:

- Frontend: `http://localhost:3000`
- Strapi admin: `http://localhost:1337/admin`
- MinIO console: `http://localhost:9001`
- Cantaloupe: `http://localhost:8182`

Default local MinIO credentials come from `.env.example`:

```text
MINIO_ROOT_USER=almadar
MINIO_ROOT_PASSWORD=change-me-minio-password
```

For real work, change secrets in `.env`. Do not commit `.env`.

## Usage Notes

Use Docker Compose for day-to-day application development. It is the quickest path for running the frontend, Strapi, PostgreSQL, MinIO, and Cantaloupe together with local source mounts.

Use k3d when validating Kubernetes manifests or cluster behavior. The k3d environment binds the same local ports as Docker Compose, so stop Compose first:

```bash
docker compose down
./infrastructure/k3d/bootstrap.sh
kubectl -n dev get pods
```

Delete the k3d cluster when finished:

```bash
./infrastructure/k3d/delete.sh
```

Use Helm when validating deployable application packaging. Charts live under `infrastructure/helm/` and have separate values overlays for `dev`, `test`, and `prod`.

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

The `dev` values are intended for local development. The `prod` values assume a production image or deployment pipeline provides application code and production secrets.

## OCI Infrastructure

Production infrastructure is managed with Terraform under `infrastructure/terraform/`.

```text
infrastructure/terraform/
  modules/
    network/
    object-storage/
    kubernetes/
    kubernetes-rbac/
    managed-postgresql/
    vault-secrets/
  environments/
    network/
    object-storage/
    postgresql/
    oke/
    oke-rbac/
    vault/
```

The OCI regions currently targeted are:

- Riyadh: `me-riyadh-1`
- Jeddah: `me-jeddah-1`

Recommended provisioning order:

1. Network: `infrastructure/terraform/environments/network`
2. Object Storage: `infrastructure/terraform/environments/object-storage`
3. PostgreSQL: `infrastructure/terraform/environments/postgresql`
4. OKE: `infrastructure/terraform/environments/oke`
5. OKE namespaces and RBAC: `infrastructure/terraform/environments/oke-rbac`
6. Vault secrets: `infrastructure/terraform/environments/vault`
7. External Secrets manifests: `infrastructure/kubernetes/external-secrets`

Each Terraform environment includes a README and a `terraform.tfvars.example`.
Copy the example to `terraform.tfvars`, fill in real OCI values locally, then run:

```bash
terraform init
terraform plan
terraform apply
```

Do not commit `terraform.tfvars` or generated kubeconfig files.

## Secrets

Application secrets are stored in OCI Vault and synchronized into Kubernetes by
External Secrets Operator. Secret values are not stored in Git.

OCI Vault stores per-environment JSON payloads for:

- PostgreSQL credentials
- JWT secrets
- Strapi secrets
- S3-compatible Object Storage credentials

External Secrets creates an `almadar-secrets` Kubernetes Secret in each
application namespace:

- `dev`
- `test`
- `prod`

The Strapi and Cantaloupe Helm charts already read from `almadar-secrets`.

Apply the External Secrets manifests after OKE, namespaces, Vault, and IAM
policy configuration are in place:

```bash
kubectl apply -k infrastructure/kubernetes/external-secrets
```

Terraform state for the Vault stack contains secret payloads because Terraform
manages OCI Vault secret versions. Use an encrypted remote backend for shared
environments.

## Make Targets

```bash
make bootstrap    # Install frontend and Strapi dependencies locally
make local-up     # Start Docker Compose services
make local-down   # Stop Docker Compose services
make test         # Run test scripts where defined
make lint         # Run lint scripts where defined
```

The Compose stack runs `npm ci` inside the app containers, so a local `make bootstrap` is only needed when you want to run app commands directly on your host.

## Local Development

Run everything in Docker:

```bash
docker compose up -d
docker compose logs -f frontend strapi
```

Run the frontend directly on your host:

```bash
cd apps/frontend
npm install
npm run dev
```

Run Strapi directly on your host:

```bash
cd apps/strapi
npm install
npm run develop
```

When running apps on the host, keep the Docker services running for PostgreSQL, MinIO, and Cantaloupe.

If ports are already in use, either stop the conflicting service or change the relevant port in `.env` before starting Compose:

```env
FRONTEND_PORT=3000
STRAPI_PORT=1337
POSTGRES_PORT=5432
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
CANTALOUPE_PORT=8182
```

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

For OCI Object Storage, keep the same code and change environment values:

```env
S3_ENDPOINT=https://<namespace>.compat.objectstorage.<oci-region>.oraclecloud.com
S3_REGION=<oci-region>
S3_ACCESS_KEY_ID=<oci-customer-secret-key-access-key>
S3_SECRET_ACCESS_KEY=<oci-customer-secret-key-secret>
S3_FORCE_PATH_STYLE=true
```

## Strapi Uploads

Strapi is configured in `apps/strapi/config/plugins.ts` to use `@strapi/provider-upload-aws-s3`.

To verify uploads locally:

1. Open `http://localhost:1337/admin`.
2. Create the first admin user if needed.
3. Upload a file in the Media Library.
4. Confirm the object appears in MinIO under `strapi-dev/uploads/`.

You can inspect buckets with:

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

Cantaloupe is configured in `infrastructure/cantaloupe/cantaloupe.properties` and reads source images via `S3Source` from `iiif-dev`.

Example IIIF endpoints:

```text
http://localhost:8182/iiif/2/<object-key>/info.json
http://localhost:8182/iiif/2/<object-key>/full/256,/0/default.jpg
http://localhost:8182/iiif/2/<object-key>/0,0,512,512/256,/0/default.jpg
```

The server supports JPEG, PNG, and TIFF source images.

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

## Useful Commands

View logs:

```bash
docker compose logs -f
```

Restart one service:

```bash
docker compose up -d --force-recreate strapi
```

Stop services:

```bash
docker compose down
```

Stop services and remove local volumes:

```bash
docker compose down -v
```

Validate configuration:

```bash
docker compose config --quiet
make lint
```

## Troubleshooting

If Strapi or the frontend takes time on first boot, check logs. The first container start installs dependencies into named Docker volumes.

```bash
docker compose logs -f strapi frontend
```

If MinIO buckets are missing, rerun the bucket initializer:

```bash
docker compose up -d --force-recreate minio-init
```

If Cantaloupe returns `404` for an image, confirm the object key exists in `iiif-dev` and matches the URL identifier exactly.
