# DECISIONS.md

# AlMadar Platform Infrastructure Decisions

**Status:** Active

**Last Updated:** 2026-06-21

This document records the major architectural and operational decisions for the AlMadar platform.

The purpose of this document is to provide a concise reference for platform engineers, developers, vendors, project managers, and future maintainers.

Detailed rationale belongs in individual ADRs.

---

# Platform Goals

The platform must:

* Support the Islamic Arts Biennale digital experience.
* Operate within Saudi Arabian hosting requirements.
* Minimize operational complexity.
* Minimize monthly infrastructure costs.
* Support long-term sustainability beyond any individual vendor.
* Support local development environments that closely mirror production.
* Be fully reproducible through Infrastructure as Code.

---

# Decision 001

## OCI Is The Primary Cloud Provider

### Decision

All production infrastructure will be hosted in Oracle Cloud Infrastructure (OCI).

### Scope

Includes:

* Kubernetes
* PostgreSQL
* Object Storage
* Networking
* Secrets management

### Rationale

* Existing organizational investment in OCI.
* Existing Saudi-region availability.
* Compliance with project requirements.
* Reduced vendor complexity.

### Consequences

* Platform architecture should avoid OCI-specific application code.
* OCI should remain a deployment target rather than an application dependency.

---

# Decision 002

## Kubernetes Is The Deployment Platform

### Decision

OCI Kubernetes Engine (OKE) will be the primary deployment platform.

### Scope

All application services:

* Next.js
* Strapi
* Cantaloupe
* Supporting services

### Rationale

* Consistent deployment process.
* Reproducible environments.
* Supports future scaling requirements.
* Reduces custom deployment logic.

### Consequences

* Helm becomes the standard deployment mechanism.
* Team members should understand Kubernetes fundamentals.

---

# Decision 003

## Single Cluster Strategy

### Decision

The platform will use a single OKE cluster.

Namespaces:

* dev
* test
* prod

### Rationale

* Lower operational cost.
* Reduced maintenance burden.
* Simpler monitoring.
* Simpler CI/CD.

### Alternatives Rejected

Separate clusters per environment.

Reason:

Operational overhead exceeds current project requirements.

### Revisit Trigger

Reevaluate if:

* Security requirements change.
* Compliance requirements change.
* Production workload significantly increases.

---

# Decision 004

## PostgreSQL As Primary Data Store

### Decision

PostgreSQL is the system of record.

### Scope

* Strapi content
* Metadata
* Application configuration
* Search indexing metadata

### Rationale

* Mature ecosystem.
* Existing team expertise.
* Strong support within Strapi.

### Consequences

No additional database technologies should be introduced without documented justification.

---

# Decision 005

## OpenSearch Deferred

### Decision

OpenSearch is not part of Phase 1.

### Rationale

Current dataset size does not justify:

* Additional infrastructure
* Additional operational burden
* Additional cost

PostgreSQL Full Text Search is sufficient for initial deployment.

### Revisit Trigger

Reevaluate when:

* Large PDF collections are introduced.
* Audio/video discovery becomes significant.
* Search performance becomes a documented issue.

---

# Decision 006

## Object Storage Is Canonical Asset Storage

### Decision

All uploaded assets are stored in OCI Object Storage.

### Scope

* IIIF images
* Strapi uploads
* Derivative assets

### Bucket Structure

IIIF:

* iiif-dev
* iiif-test
* iiif-prod

CMS:

* strapi-dev
* strapi-test
* strapi-prod

### Consequences

Application containers remain stateless.

No asset storage on local container filesystems.

---

# Decision 007

## MinIO Mirrors OCI Locally

### Decision

Local development uses MinIO.

### Rationale

* S3 compatibility.
* Easy local deployment.
* Closely mirrors OCI Object Storage usage patterns.

### Consequences

Applications must communicate exclusively through S3 APIs.

Application code must not distinguish between MinIO and OCI Object Storage.

---

# Decision 008

## Cantaloupe Provides IIIF Services

### Decision

Cantaloupe is the IIIF image server.

### Responsibilities

* Tile generation
* Image delivery
* Thumbnail generation
* IIIF Image API support

### Consequences

Image rendering logic belongs in Cantaloupe.

IIIF functionality should not be duplicated elsewhere.

---

# Decision 009

## Strapi Is The Editorial System

### Decision

Strapi is the CMS platform.

### Responsibilities

* Content management
* Metadata management
* Editorial workflows
* IIIF asset management

### Consequences

Business logic should be minimized within Strapi whenever practical.

Complex integrations should be implemented as independent services.

---

# Decision 010

## Next.js Is The Public Application Layer

### Decision

Next.js is the primary frontend framework.

### Responsibilities

* Public website
* Search interfaces
* Exhibition experiences
* IIIF viewer integrations

### Consequences

Public-facing application logic belongs in Next.js.

---

# Decision 011

## Infrastructure As Code Is Mandatory

### Decision

Infrastructure must be managed through source control.

### Approved Technologies

* Terraform
* Helm
* Kubernetes manifests

### Prohibited Practices

* Manual OCI resource creation
* Manual Kubernetes deployments
* Undocumented infrastructure changes

### Consequences

Infrastructure changes require pull requests.

---

# Decision 012

## OCI Vault Is The Source Of Truth For Secrets

### Decision

Secrets are stored in OCI Vault.

### Scope

* Database credentials
* JWT secrets
* API keys
* Object storage credentials

### Prohibited

Secrets stored in:

* Git repositories
* Helm values
* Terraform variables
* GitHub Actions workflows

### Consequences

External Secrets Operator is required.

---

# Decision 013

## OCI-Hosted GitHub Runners

### Decision

GitHub Actions execute on OCI-hosted runners.

### Rationale

* Regional compliance requirements.
* Reduced exposure of credentials.
* Consistent deployment environment.

### Implementation

Actions Runner Controller (ARC).

### Consequences

No long-lived deployment credentials stored in GitHub.

---

# Decision 014

## Cloudflare Handles Edge Services

### Decision

Cloudflare is responsible for:

* DNS
* CDN
* WAF
* TLS termination

### Consequences

Cloudflare configuration must be documented.

Cloudflare is not the source of truth for infrastructure.

---

# Decision 015

## Local Development Must Resemble Production

### Decision

Every production service should have a local equivalent.

### Local Services

* k3d
* PostgreSQL
* MinIO
* Strapi
* Cantaloupe
* Next.js

### Rationale

Reduce deployment surprises.

### Consequences

Development workflows should be validated locally before OCI deployment.

---

# Decision 016

## Deployments Must Be Automated

### Decision

All deployments occur through CI/CD.

### Flow

GitHub
→ OCI Runner
→ OCI Registry
→ Helm Deployment
→ Kubernetes

### Consequences

Manual production deployments are discouraged.

---

# Decision 017

## Recovery Is A First-Class Requirement

### Decision

Infrastructure is not considered complete until recovery procedures exist.

### Required Recovery Scenarios

* Kubernetes rebuild
* PostgreSQL restore
* Bucket recovery
* Environment recreation

### Consequences

Every major component must have a documented recovery procedure.

---

# Decision 018

## Cost Is A Design Constraint

### Decision

Operational cost is a primary architectural concern.

### Preferred Strategy

* Reuse infrastructure where practical.
* Share Kubernetes clusters.
* Delay nonessential services.
* Prefer managed services when operational savings outweigh direct cost increases.

### Consequences

Every new service should include:

* Estimated monthly cost
* Operational impact
* Business justification

---

# Decision 019

## Documentation Is Part Of The Deliverable

### Decision

Features are incomplete without documentation.

### Minimum Documentation

* Architecture overview
* Deployment procedures
* Recovery procedures
* Configuration references

### Consequences

Undocumented infrastructure is considered unfinished work.

---

# Decision 020

## Vendor Independence

### Decision

The platform must remain operable regardless of vendor participation.

### Requirements

* Infrastructure definitions in source control.
* Documentation in source control.
* No vendor-owned deployment processes.
* No vendor-exclusive operational knowledge.

### Success Metric

A new engineer can deploy, operate, and recover the platform without assistance from the original implementation team.
