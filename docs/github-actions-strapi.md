# Strapi GitHub Actions Image Build

The Strapi workflow is defined in:

```text
.github/workflows/strapi.yml
```

For the August 1 production launch, this workflow runs on GitHub-hosted runners.
It builds and pushes immutable Strapi images to OCIR. It does not deploy to OKE.

## Flow

1. Install dependencies with `npm ci`.
2. Run `npm test`, which currently builds the Strapi application.
3. Build the Strapi Docker image from `apps/strapi/Dockerfile`.
4. Push the image to OCIR with two tags:
   - `<environment>-<git-sha>`
   - `<environment>-latest`

Branch mapping:

- `develop` builds a `dev-*` image.
- `release/*` builds a `test-*` image.
- `main` builds a `prod-*` image.
- `workflow_dispatch` can build for `dev`, `test`, or `prod`.

## GitHub Variables

Configure these repository or organization variables:

```text
OCIR_REGISTRY
OCIR_NAMESPACE
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
```

Do not commit OCIR tokens or OCI credentials.

## Deployment

Deployment is intentionally separate from the GitHub Actions image build during
the August 1 launch. Use the approved Helm deployment flow in:

```text
docs/production-deployment-plan.md
```

The deployment operator supplies the image tag produced by this workflow:

```bash
export STRAPI_IMAGE="<OCIR_REGISTRY>/<OCIR_NAMESPACE>/almadar-strapi"
export STRAPI_TAG="prod-<git-sha>"
```

Then run the Strapi Helm command from the production deployment plan.

## Validation

Run the platform validation suite after deployment:

```bash
cd tests/validation
npm ci
npm test
```

The validation suite checks:

- Strapi health.
- PostgreSQL query.
- Strapi image upload.
- Object Storage write.
- Cantaloupe `info.json`.
- IIIF thumbnail generation.
- Next.js frontend availability.
