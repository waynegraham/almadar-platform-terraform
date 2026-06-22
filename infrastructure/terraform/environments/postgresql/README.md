# OCI Database with PostgreSQL

Terraform root for Strapi PostgreSQL on OCI Database with PostgreSQL, Oracle's
managed PostgreSQL service.

## DB Systems

This stack creates one OCI-managed PostgreSQL DB system per Strapi environment:

- `strapi_dev`
- `strapi_test`
- `strapi_prod`

The OCI PostgreSQL Terraform resource manages DB systems. OCI does not expose a
separate Terraform resource for logical PostgreSQL databases, so the names above
are emitted in the Strapi connection outputs as `DATABASE_NAME`.

## Strapi Connection Outputs

Use the sensitive `strapi_environment` output to populate Strapi secrets:

```bash
terraform output -json strapi_environment
```

Each environment includes:

- `DATABASE_CLIENT`
- `DATABASE_HOST`
- `DATABASE_PORT`
- `DATABASE_NAME`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `DATABASE_SSL`
- `DATABASE_SSL_REJECT_UNAUTHORIZED`

## Usage

```bash
cd infrastructure/terraform/environments/postgresql
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Use private subnet IDs and PostgreSQL NSG IDs from the network stack outputs.
