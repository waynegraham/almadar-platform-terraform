# Strapi GitHub Actions Deployment

The active launch deployment path is:

```text
.github/workflows/deploy-dev.yml
.github/workflows/deploy-prod.yml
```

Those workflows run on the OCI self-hosted runner, build the Strapi Docker image
from `apps/strapi/Dockerfile`, push it to GHCR or OCIR, SSH to the app VM,
update the remote Compose environment file, and restart the Docker Compose
stack.

The production Strapi container connects to external OCI managed PostgreSQL and
uses OCI Object Storage through the S3-compatible upload provider. No local
PostgreSQL container is deployed by these workflows.

Required runner labels, secrets, variables, and environment approval settings
are documented in:

```text
docs/github-actions-runners.md
```

