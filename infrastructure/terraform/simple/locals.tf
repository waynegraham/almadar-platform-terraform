locals {
  compartment_id = coalesce(
    var.compartment_id,
    try(data.oci_identity_compartments.selected[0].compartments[0].id, null)
  )

  common_tags = merge(var.freeform_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    LaunchPath  = "simple"
  })

  name_prefix = "${var.project_name}-${var.environment}"

  bucket_names = {
    strapi_uploads = coalesce(var.bucket_names.strapi_uploads, "${local.name_prefix}-strapi-uploads")
    iiif_sources   = coalesce(var.bucket_names.iiif_sources, "${local.name_prefix}-iiif-sources")
    backups        = coalesce(var.bucket_names.backups, "${local.name_prefix}-backups")
  }

  availability_domain = coalesce(
    var.availability_domain,
    data.oci_identity_availability_domains.this.availability_domains[0].name
  )
}

