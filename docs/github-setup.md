# GitHub Repository Setup

## Purpose

This document describes how to create, configure, and manage the AlMadar Platform GitHub repository.

The repository serves as the source of truth for:

* Application code
* Infrastructure code
* CI/CD workflows
* Operational documentation
* Architectural decisions

No production infrastructure should exist without a corresponding representation in this repository.

---

# Repository Creation

## Repository Name

Recommended:

```text
almadar-platform
```

Repository visibility:

```text
Private
```

Reason:

The repository contains infrastructure definitions, deployment workflows, and operational documentation.

---

# Organization Structure

Recommended ownership:

```text
AlMadar-Digital
└── almadar-platform
```

Avoid creating repositories under individual user accounts.

Repositories owned by individuals eventually become organizational hostage situations.

---

# Initial Repository Structure

```text
almadar-platform/

├── apps/
│   ├── frontend/
│   └── strapi/
│
├── infrastructure/
│   ├── terraform/
│   ├── helm/
│   └── k3d/
│
├── docs/
│
├── scripts/
│
├── .github/
│   └── workflows/
│
├── AGENTS.md
├── DECISIONS.md
├── README.md
└── Makefile
```

---

# Repository Settings

## Default Branch

Set:

```text
main
```

Do not use:

```text
master
```

---

# Branch Strategy

Environment mapping:

```text
develop
    ↓
dev

release/*
    ↓
test

main
    ↓
prod
```

### Branch Purposes

#### main

Production code only.

Protected.

#### develop

Primary integration branch.

Used for active development.

#### release/*

Pre-production validation.

Example:

```text
release/2026-08-launch
```

---

# Branch Protection Rules

## main

Require:

* Pull request
* 1 approval minimum
* Passing CI checks
* Linear history
* No force pushes

Recommended:

```text
✓ Require pull request reviews
✓ Require status checks
✓ Require conversation resolution
✓ Require signed commits (optional)
✓ Restrict force pushes
```

---

## develop

Require:

* Pull request
* Passing CI

Less restrictive than production.

---

# Teams

Recommended Teams

## Platform Administrators

Access:

```text
Admin
```

Responsibilities:

* Infrastructure
* Security
* Repository settings

Small group.

---

## Developers

Access:

```text
Write
```

Responsibilities:

* Application code
* Pull requests

---

## Reviewers

Access:

```text
Write
```

Responsibilities:

* Review pull requests
* Approve deployments

---

## Observers

Access:

```text
Read
```

Responsibilities:

* Project visibility
* Non-technical stakeholders

---

# Labels

Create the following labels.

## Infrastructure

```text
infrastructure
terraform
kubernetes
cloudflare
```

---

## Application

```text
frontend
strapi
iiif
cantaloupe
```

---

## Operations

```text
bug
incident
security
documentation
```

---

## Planning

```text
enhancement
technical-debt
question
```

---

# Issue Templates

Create:

```text
.github/ISSUE_TEMPLATE/
```

Templates:

### Bug Report

Capture:

* Description
* Reproduction steps
* Expected behavior
* Environment

---

### Infrastructure Change

Capture:

* Reason
* Risk
* Rollback plan

---

### Feature Request

Capture:

* Business requirement
* Technical impact

---

# Pull Request Template

Create:

```text
.github/pull_request_template.md
```

Template:

```markdown
## Summary

Describe the change.

## Testing

- [ ] Unit tests
- [ ] Integration tests
- [ ] Local validation completed

## Infrastructure Impact

Describe infrastructure changes.

## Documentation

- [ ] Documentation updated

## Rollback Plan

Describe rollback procedure.
```

---

# GitHub Actions

Create:

```text
.github/workflows/
```

Initial workflows:

```text
frontend-ci.yml
strapi-ci.yml
terraform-plan.yml
terraform-apply.yml
```

---

# GitHub Container Registry

Not used.

Container images should be stored in:

OCI Container Registry

Reason:

Keeps deployment assets inside OCI.

---

# Secrets

Repository secrets should be minimized.

Preferred:

OCI Vault
↓
External Secrets Operator
↓
Kubernetes

Avoid storing production credentials in GitHub.

---

# Environments

Create:

```text
dev
test
prod
```

GitHub Environments.

---

## Dev

Auto-deploy allowed.

---

## Test

Manual approval recommended.

---

## Prod

Approval required.

Deployment restricted.

---

# CODEOWNERS

Create:

```text
.github/CODEOWNERS
```

Example:

```text
# Infrastructure
/infrastructure/ @platform-team

# Frontend
/apps/frontend/ @frontend-team

# Strapi
/apps/strapi/ @backend-team

# Documentation
/docs/ @platform-team
```

All production-impacting changes should have explicit reviewers.

---

# Dependabot

Enable Dependabot.

Create:

```text
.github/dependabot.yml
```

Monitor:

* npm
* GitHub Actions
* Docker images

Weekly schedule is sufficient.

---

# Discussions

Enable GitHub Discussions.

Use for:

* Architecture questions
* Operational procedures
* Design proposals

Avoid using Issues for open-ended discussions.

---

# Projects

Create a GitHub Project.

Suggested columns:

```text
Backlog
Ready
In Progress
Review
Testing
Done
```

Avoid multiple overlapping project systems.

One source of truth.

---

# Releases

Tag production deployments.

Format:

```text
vYYYY.MM.DD
```

Example:

v2026.08.01

Every production deployment should have a corresponding Git tag.

---

# Required Documentation

The following files must exist before the first production deployment:

```text
README.md
AGENTS.md
DECISIONS.md
```

The following directories must also exist:

```text
docs/adr/
docs/runbooks/
docs/architecture/
```

---

# Success Criteria

A new engineer should be able to:

1. Clone the repository.
2. Understand repository structure.
3. Run the local environment.
4. Submit a pull request.
5. Deploy to development.
6. Locate operational documentation.

without relying on institutional knowledge or access to the original implementation team.
