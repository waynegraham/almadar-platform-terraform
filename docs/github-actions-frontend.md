# Frontend GitHub Actions Deployment

The active launch deployment path is:

```text
.github/workflows/deploy-dev.yml
.github/workflows/deploy-prod.yml
```

Those workflows run on the OCI self-hosted runner, build the frontend Docker
image from `apps/frontend/Dockerfile`, push it to GHCR or OCIR, SSH to the app
VM, update the remote Compose environment file, and restart the Docker Compose
stack.

The older standalone frontend image-build-only workflow is not the production
deployment path for the simplified launch architecture.

Required runner labels, secrets, variables, and environment approval settings
are documented in:

```text
docs/github-actions-runners.md
```

