# ADR-003: OCI Object Storage

Date: 2026-06-21

Status: Accepted

## Context

The platform must store IIIF source images and Strapi media outside application
containers. Containers must remain stateless so they can be replaced, scaled,
and recovered without losing media.

The expected collection size is modest, around 1,000 collection objects, but the
platform still needs durable storage, versioning, lifecycle policies, and a
production service that integrates with OCI infrastructure and IAM.

## Decision

Use OCI Object Storage for production and shared environment media storage.

Maintain separate buckets by workload and environment:

- `iiif-dev`
- `iiif-test`
- `iiif-prod`
- `strapi-dev`
- `strapi-test`
- `strapi-prod`

Provision buckets and IAM policies through Terraform. Store access credentials
in OCI Vault and synchronize them into Kubernetes through External Secrets.

## Consequences

Positive consequences:

- Images and uploads are durable outside Kubernetes pods.
- Buckets can be recreated through Terraform.
- Bucket separation reduces accidental cross-environment writes.
- OCI Object Storage aligns with the selected cloud provider.
- S3-compatible configuration keeps local MinIO and production OCI usage
  consistent at the application layer.

Negative consequences:

- Application behavior must account for OCI-specific S3 compatibility details.
- Backup and restore procedures for buckets must be tested separately from
  Kubernetes recovery.
- Object Storage credentials are sensitive and must be managed through Vault and
  External Secrets, not Helm values or GitHub workflow files.

## Alternatives Considered

- Kubernetes persistent volumes for media: rejected because media would be tied
  to cluster lifecycle and harder to recover during OKE loss.
- Local filesystem storage in Strapi or Cantaloupe containers: rejected because
  it breaks stateless deployment and production recovery requirements.
- Cloudflare R2: technically viable S3-compatible storage, but it would split
  core infrastructure across OCI and Cloudflare without a current requirement.
- Dedicated NAS or file storage: unnecessary operational complexity for the
  current scale and access pattern.
