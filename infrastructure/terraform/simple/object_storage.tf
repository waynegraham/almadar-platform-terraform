resource "oci_objectstorage_bucket" "strapi_uploads" {
  compartment_id        = local.compartment_id
  namespace             = data.oci_objectstorage_namespace.this.namespace
  name                  = local.bucket_names.strapi_uploads
  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  versioning            = var.bucket_versioning
  object_events_enabled = false
  freeform_tags         = local.common_tags
}

resource "oci_objectstorage_bucket" "iiif_sources" {
  compartment_id        = local.compartment_id
  namespace             = data.oci_objectstorage_namespace.this.namespace
  name                  = local.bucket_names.iiif_sources
  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  versioning            = var.bucket_versioning
  object_events_enabled = false
  freeform_tags         = local.common_tags
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id        = local.compartment_id
  namespace             = data.oci_objectstorage_namespace.this.namespace
  name                  = local.bucket_names.backups
  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  versioning            = var.bucket_versioning
  object_events_enabled = false
  freeform_tags         = local.common_tags
}

resource "oci_objectstorage_object_lifecycle_policy" "backups" {
  bucket    = oci_objectstorage_bucket.backups.name
  namespace = data.oci_objectstorage_namespace.this.namespace

  rules {
    action      = "DELETE"
    is_enabled  = true
    name        = "delete-old-previous-versions"
    target      = "previous-object-versions"
    time_amount = var.backup_previous_version_retention_days
    time_unit   = "DAYS"
  }
}

