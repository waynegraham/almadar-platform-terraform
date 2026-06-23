# OCI Object Storage

Terraform root for AlMadar platform Object Storage buckets.

## Buckets

- `iiif-dev`
- `iiif-test`
- `iiif-prod`
- `strapi-dev`
- `strapi-test`
- `strapi-prod`

Each bucket has versioning enabled and lifecycle policies for:

- Aborting incomplete multipart uploads after 7 days.
- Deleting previous object versions after 180 days.

## IAM

The stack creates one OCI IAM policy with per-bucket statements for:

- Admin group: manage buckets and objects.
- Writer group: manage objects.
- Reader group: read objects.

Create the referenced OCI IAM groups before applying this stack, then set their names in `terraform.tfvars`.

## Usage

```bash
cd infrastructure/terraform/environments/object-storage
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```
