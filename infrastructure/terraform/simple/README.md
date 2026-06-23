# Simplified Terraform Launch Stack

This Terraform root is the August 1 launch path for AlMadar. It provisions a
small OCI VM-based production stack:

- VCN, public app subnet, public runner subnet, and private database subnet,
- security lists and Network Security Groups,
- application VM for Docker Compose,
- separate GitHub self-hosted runner VM,
- OCI Database with PostgreSQL,
- Object Storage buckets for Strapi uploads, IIIF source images, and backups,
- optional OCI Vault, KMS key, and secrets,
- outputs needed by deployment and operations.

It intentionally does not provision OKE, Helm, Actions Runner Controller,
External Secrets Operator, OpenSearch, OCI Network Firewall, multi-region
resources, or Kubernetes-related IAM.

## Preserved Future Terraform

The earlier Terraform code has been moved under:

```text
infrastructure/terraform/future/
```

Use that directory only as a reference for future Kubernetes or multi-stack
work. It is not part of the simplified launch path.

## Usage

Create a local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with real OCI values. Do not commit it.

Initialize and plan:

```bash
terraform init
terraform plan
```

Apply after review:

```bash
terraform apply
```

## Notes

- `http_source_cidrs` should be restricted to Cloudflare origin CIDRs for
  production where possible.
- `ssh_source_cidrs` should be restricted to approved admin or VPN addresses.
- The app VM block volume is for Docker data, logs, and Cantaloupe cache only.
  Durable media belongs in Object Storage.
- If `enable_vault = true`, Terraform state contains the secret payloads used
  to create OCI Vault secret versions. Use an encrypted remote backend before
  using Vault secrets in a shared environment.
- VM cloud-init installs Docker and Compose but does not register the GitHub
  runner or deploy the application. Those steps belong in `deploy/runner` and
  `deploy/compose`.

