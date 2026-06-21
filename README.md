# almadar-platform

`almadar-platform` is a monorepo for the Almadar platform. It contains a Next.js frontend, a Strapi CMS, infrastructure assets, operational documentation, and GitHub Actions workflows.

## Repository Layout

```text
apps/
  frontend/         Next.js frontend application
  strapi/           Strapi CMS application

infrastructure/
  terraform/        Terraform modules and environments
  helm/             Helm charts and values
  k3d/              Local Kubernetes cluster configuration
  postgresql/       Local PostgreSQL initialization assets

docs/               Project documentation

.github/
  workflows/        GitHub Actions workflows
```

## Prerequisites

- Node.js 20 or newer
- npm
- Docker
- Docker Compose
- Terraform
- Helm
- kubectl
- k3d

## Quick Start

Install application dependencies:

```bash
make bootstrap
```

Start local infrastructure services:

```bash
make local-up
```

Run the frontend:

```bash
cd apps/frontend
npm run dev
```

Run Strapi:

```bash
cd apps/strapi
npm run develop
```

Stop local infrastructure services:

```bash
make local-down
```

## Development Commands

```bash
make bootstrap    # Install app dependencies
make local-up     # Start local Docker Compose services
make local-down   # Stop local Docker Compose services
make test         # Run tests for all apps that define them
make lint         # Run lint checks for all apps that define them
```

## Applications

### Frontend

The frontend is a Next.js application in `apps/frontend`.

Common commands:

```bash
cd apps/frontend
npm run dev
npm run build
npm run start
npm run lint
```

### Strapi

The CMS is a Strapi application in `apps/strapi`.

Common commands:

```bash
cd apps/strapi
npm run develop
npm run build
npm run start
```

## Infrastructure

Infrastructure code is grouped by deployment tool:

- `infrastructure/terraform` for cloud resources
- `infrastructure/helm` for Kubernetes packaging
- `infrastructure/k3d` for local Kubernetes setup

