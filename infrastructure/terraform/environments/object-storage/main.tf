locals {
  bucket_names = toset([
    "iiif-dev",
    "iiif-test",
    "iiif-prod",
    "strapi-dev",
    "strapi-test",
    "strapi-prod",
  ])

  buckets = {
    for name in local.bucket_names : name => {
      name       = name
      versioning = "Enabled"

      lifecycle_rules = [
        {
          name        = "abort-incomplete-multipart-uploads"
          action      = "ABORT"
          target      = "multipart-uploads"
          time_amount = 7
          time_unit   = "DAYS"
        },
        {
          name        = "delete-old-previous-versions"
          action      = "DELETE"
          target      = "previous-object-versions"
          time_amount = 180
          time_unit   = "DAYS"
        }
      ]
    }
  }

  bucket_policy_statements = flatten([
    for bucket_name in sort(tolist(local.bucket_names)) : [
      "Allow group ${var.object_storage_admin_group_name} to manage buckets in compartment id ${var.compartment_id} where target.bucket.name = '${bucket_name}'",
      "Allow group ${var.object_storage_admin_group_name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${bucket_name}'",
      "Allow group ${var.object_storage_writer_group_name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${bucket_name}'",
      "Allow group ${var.object_storage_reader_group_name} to read objects in compartment id ${var.compartment_id} where target.bucket.name = '${bucket_name}'",
    ]
  ])

  common_tags = merge(var.freeform_tags, {
    Project   = var.project_name
    ManagedBy = "terraform"
  })
}

module "object_storage" {
  source = "../../modules/object-storage"

  compartment_id = var.compartment_id
  name_prefix    = var.project_name
  region_key     = replace(var.region, "-", "")
  namespace      = var.object_storage_namespace
  buckets        = local.buckets

  iam_policy_compartment_id = coalesce(var.policy_compartment_id, var.compartment_id)
  iam_policy_name           = "${var.project_name}_object_storage_access"
  iam_policy_description    = "Access policy for AlMadar IIIF and Strapi Object Storage buckets."
  iam_policy_statements     = local.bucket_policy_statements

  freeform_tags = local.common_tags
}
