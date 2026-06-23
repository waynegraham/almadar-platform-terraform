# Frontend GitHub Actions Image Build

The frontend workflow is defined in:

```text
.github/workflows/frontend.yml
```

For the August 1 production launch, this workflow runs on GitHub-hosted runners.
It builds and pushes immutable frontend images to OCIR. It does not deploy to
OKE.

## Flow

1. Install dependencies with `npm ci`.
2. Run lint.
3. Run tests.
4. Build the Next.js application.
5. Build the Docker image from `apps/frontend/Dockerfile`.
6. Push the image to OCIR with two tags:
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

## GitHub Secrets

Configure these repository or organization secrets:

```text
OCIR_USERNAME
OCIR_AUTH_TOKEN
```

## Deployment

Deployment is intentionally separate from the GitHub Actions image build during
the August 1 launch. Use the approved Helm deployment flow in:

```text
docs/production-deployment-plan.md
```

The deployment operator supplies the image tag produced by this workflow:

```bash
export FRONTEND_IMAGE="<OCIR_REGISTRY>/<OCIR_NAMESPACE>/almadar-frontend"
export FRONTEND_TAG="prod-<git-sha>"
```
