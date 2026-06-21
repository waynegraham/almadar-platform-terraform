# Strapi GitHub Actions Deployment

The Strapi workflow is defined in:

```text
.github/workflows/strapi.yml
```

It runs on the OCI-hosted GitHub Actions runner label:

```text
almadar-oci-oke
```

## Flow

1. Install dependencies with `npm ci`.
2. Run `npm test`, which builds the Strapi application.
3. Build the Strapi Docker image from `apps/strapi/Dockerfile`.
4. Push the image to OCIR.
5. Run the Helm pre-install/pre-upgrade migration job.
6. Deploy Strapi with Helm and wait for rollout completion.
7. Run platform validation tests for Strapi, PostgreSQL, Object Storage,
   Cantaloupe, IIIF thumbnails, and the frontend.

Branch mapping:

- `develop` deploys to `dev`.
- `release/*` deploys to `test`.
- `main` deploys to `prod`.
- `workflow_dispatch` can deploy to `dev`, `test`, or `prod`.

## GitHub Variables

Configure these repository or organization variables:

```text
OCIR_REGISTRY
OCIR_NAMESPACE
FRONTEND_URL
STRAPI_URL
CANTALOUPE_URL
POSTGRES_HOST
POSTGRES_PORT
POSTGRES_DB
POSTGRES_USER
POSTGRES_SSL
S3_ENDPOINT
S3_REGION
S3_FORCE_PATH_STYLE
IIIF_BUCKET
```

Example:

```text
OCIR_REGISTRY=iad.ocir.io
OCIR_NAMESPACE=<tenancy_namespace>
```

## GitHub Secrets

Configure these repository or organization secrets:

```text
OCIR_USERNAME
OCIR_AUTH_TOKEN
OKE_KUBECONFIG_B64
POSTGRES_PASSWORD
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
STRAPI_UPLOAD_TOKEN
```

`OKE_KUBECONFIG_B64` is a base64-encoded kubeconfig for the target OKE cluster:

```bash
base64 -i generated/oke-kubeconfig.yaml
```

Do not commit kubeconfig files, OCIR tokens, or OCI credentials.

`STRAPI_UPLOAD_TOKEN` must be a Strapi API token or equivalent bearer token
with permission to upload media through `/api/upload`. The validation pipeline
intentionally fails if this token is missing or does not have upload permission.

## GitHub Environments

Create GitHub Environments named:

```text
dev
test
prod
```

Use required reviewers for `prod` before enabling unattended production
deployment.

## Content Model Changes

Strapi database migration files in `apps/strapi/database/migrations` are run by:

```text
npm run migrate
```

The Helm chart runs that command as a pre-install/pre-upgrade hook before the
Deployment is rolled forward. If migrations or content-type schema sync fail,
`helm upgrade --atomic` fails and rolls the release back.

## Validation

The workflow runs the Playwright validation suite in:

```text
tests/validation
```

The validation step fails the pipeline if any required platform check fails:

- Strapi health.
- PostgreSQL query.
- Strapi image upload.
- Object Storage write.
- Cantaloupe `info.json`.
- IIIF thumbnail generation.
- Next.js frontend availability.
