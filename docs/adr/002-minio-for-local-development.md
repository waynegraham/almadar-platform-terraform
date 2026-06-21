# ADR-002: MinIO for Local Development

Date: 2026-06-21

Status: Accepted

## Context

The platform stores Strapi media uploads and IIIF source images in S3-compatible
object storage. Production uses OCI Object Storage. Local development needs a
low-friction storage service that behaves like object storage without requiring
every developer to have access to OCI credentials or shared cloud buckets.

The local stack must support Docker Compose and k3d workflows. It must allow
Strapi and Cantaloupe to use the same S3-compatible application configuration
shape used in production.

## Decision

Use MinIO for local object storage in Docker Compose and k3d.

The local environment initializes development buckets such as `iiif-dev` and
`strapi-dev`. Applications use environment-driven S3-compatible settings so
local development points to MinIO while production points to OCI Object Storage.

## Consequences

Positive consequences:

- Developers can run the full platform locally without OCI access.
- Strapi and Cantaloupe exercise object-storage code paths during local
  development.
- Local bucket setup is reproducible through scripts and Kubernetes manifests.
- The application configuration remains provider-neutral and environment-driven.

Negative consequences:

- MinIO is not identical to OCI Object Storage, so provider-specific behavior
  must still be validated against OCI.
- Local public URL, ACL, and path-style behavior may differ from production.
- Developers must understand that MinIO data is disposable local development
  state, not a production backup.

## Alternatives Considered

- Use OCI Object Storage for all development: closer to production, but creates
  credential, cost, and isolation issues for local work.
- Store uploads on local container volumes: simple, but violates the production
  stateless-container model and does not test object-storage integration.
- Mock object storage in application code: faster for unit tests, but not enough
  for validating Strapi upload and Cantaloupe IIIF behavior.
- Use another S3-compatible local service: viable, but MinIO is widely used,
  easy to run in Docker, and fits the current local stack.
