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

resource "oci_objectstorage_object_lifecycle_policy" "this" {
  for_each = {
    for name, bucket in var.buckets : name => bucket
    if length(bucket.lifecycle_rules) > 0
  }

  bucket    = oci_objectstorage_bucket.this[each.key].name
  namespace = var.namespace

  dynamic "rules" {
    for_each = each.value.lifecycle_rules

    content {
      action      = rules.value.action
      is_enabled  = rules.value.is_enabled
      name        = rules.value.name
      target      = rules.value.target
      time_amount = rules.value.time_amount
      time_unit   = rules.value.time_unit

      dynamic "object_name_filter" {
        for_each = rules.value.object_name_filter == null ? [] : [rules.value.object_name_filter]

        content {
          exclusion_patterns = object_name_filter.value.exclusion_patterns
          inclusion_patterns = object_name_filter.value.inclusion_patterns
          inclusion_prefixes = object_name_filter.value.inclusion_prefixes
        }
      }
    }
  }
}

resource "oci_identity_policy" "object_storage" {
  count = length(var.iam_policy_statements) > 0 ? 1 : 0

  compartment_id = var.iam_policy_compartment_id
  description    = var.iam_policy_description
  name           = var.iam_policy_name
  statements     = var.iam_policy_statements
  freeform_tags  = local.common_tags
}
