locals {
  common_tags = merge(var.freeform_tags, {
    Region = var.region_key
  })
}

resource "oci_objectstorage_bucket" "this" {
  for_each = var.buckets

  compartment_id        = var.compartment_id
  namespace             = var.namespace
  name                  = each.value.name
  access_type           = each.value.access_type
  storage_tier          = each.value.storage_tier
  versioning            = each.value.versioning
  object_events_enabled = each.value.object_events_enabled
  auto_tiering          = each.value.auto_tiering
  freeform_tags         = local.common_tags
}
