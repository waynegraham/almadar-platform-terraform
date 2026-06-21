# OCI Terraform

Terraform for the Almadar platform on Oracle Cloud Infrastructure.

## Layout

```text
infrastructure/terraform/
  modules/
    network/          VCN, gateways, route tables, subnets, NSGs
    object-storage/   S3-compatible Object Storage buckets
    kubernetes/       OKE cluster and optional node pool
    postgresql/       OCI PostgreSQL database system
  environments/
    dev/              Riyadh and Jeddah development environment
```

## Regions

The environment is wired for:

- Riyadh: `me-riyadh-1`
- Jeddah: `me-jeddah-1`

## Usage

Create local variables:

```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with OCI tenancy, user, fingerprint, key path, compartment, and SSH key values.

Initialize and plan:

```bash
terraform init
terraform plan
```

By default, OKE node pools and PostgreSQL are disabled in the example variables to avoid provisioning compute/database capacity before the network and buckets are reviewed. Set `create_node_pool = true` and `postgresql.enabled = true` when those resources are ready to be provisioned.
