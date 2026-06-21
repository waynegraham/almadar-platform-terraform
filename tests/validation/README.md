# Platform Validation Tests

These Playwright tests validate the deployed platform after CI/CD deployment.

They verify:

- Strapi health.
- PostgreSQL connectivity.
- Strapi image upload.
- Object Storage write.
- Cantaloupe `info.json`.
- IIIF thumbnail generation.
- Next.js frontend availability.

## Required Environment

Local defaults target Docker Compose and k3d ports. Production pipelines should
set explicit values.

```bash
export FRONTEND_URL=https://www.<domain>
export STRAPI_URL=https://cms.<domain>
export CANTALOUPE_URL=https://iiif.<domain>
export POSTGRES_HOST=<postgres-host>
export POSTGRES_PORT=5432
export POSTGRES_DB=<database>
export POSTGRES_USER=<user>
export POSTGRES_PASSWORD=<password>
export POSTGRES_SSL=true
export S3_ENDPOINT=<object-storage-endpoint>
export S3_REGION=<region>
export S3_ACCESS_KEY_ID=<access-key>
export S3_SECRET_ACCESS_KEY=<secret-key>
export S3_FORCE_PATH_STYLE=false
export IIIF_BUCKET=iiif-prod
export STRAPI_UPLOAD_TOKEN=<strapi-api-token-with-upload-permission>
```

Run:

```bash
cd tests/validation
npm ci
npm test
```

The pipeline fails if any test fails.
