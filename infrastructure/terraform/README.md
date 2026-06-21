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

Edit `terraform.tfvars` with OCI tenancy, user, fingerprint, key path, compartment, Object Storage namespace, and SSH key values.

Initialize and plan:

```bash
terraform init
terraform plan
```

By default, OKE node pools, PostgreSQL, and OCI Service Gateways are disabled in the example variables to avoid provisioning compute/database capacity and to allow the sample plan to run without regional OCI service metadata lookups. Set `create_service_gateway = true`, `create_node_pool = true`, and `postgresql.enabled = true` when those resources are ready to be provisioned with real OCI credentials.
