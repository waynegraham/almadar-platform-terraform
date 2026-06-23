# OCI Terraform

Terraform for the AlMadar platform on Oracle Cloud Infrastructure.

## Active Launch Path

Use the simplified August 1 launch stack:

```text
infrastructure/terraform/simple/
```

This root provisions the VM + Docker Compose launch architecture:

- VCN, subnets, security lists, and NSGs,
- app server VM,
- GitHub self-hosted runner VM,
- OCI Database with PostgreSQL,
- Object Storage buckets for Strapi uploads, IIIF source images, and backups,
- optional OCI Vault secrets,
- outputs for deployment and operations.

## Preserved Future Terraform

The previous multi-environment and Kubernetes-oriented Terraform has been moved
under:

```text
infrastructure/terraform/future/
```

Use `future/` only as a reference for deferred OKE, Kubernetes RBAC, split
environment stacks, or post-launch expansion work. It is not part of the
August 1 launch path.

## Usage

Create local variables:

```bash
cd infrastructure/terraform/simple
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with real OCI tenancy, user, fingerprint, key path,
compartment, SSH key, PostgreSQL password, and network allowlist values.

Initialize and plan:

```bash
terraform init
terraform plan
```

Apply after review:

```bash
terraform apply
```

Do not commit `terraform.tfvars`, OCI private keys, generated SSH private keys,
or Terraform state files.
