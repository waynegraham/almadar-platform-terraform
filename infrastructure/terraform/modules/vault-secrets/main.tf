locals {
  common_tags = merge(var.freeform_tags, {
    ManagedBy = "terraform"
  })
}

resource "oci_kms_vault" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-vault"
  vault_type     = var.vault_type
  freeform_tags  = local.common_tags
}

resource "oci_kms_key" "this" {
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-secrets-key"
  management_endpoint = oci_kms_vault.this.management_endpoint
  freeform_tags       = local.common_tags

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "this" {
  for_each = var.secrets

  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.this.id
  secret_name    = each.value.secret_name
  description    = each.value.description
  freeform_tags  = local.common_tags

  secret_content {
    content_type = "BASE64"
    content      = base64encode(jsonencode(var.secret_payloads[each.key]))
    stage        = "CURRENT"
  }
}

resource "oci_identity_policy" "vault_external_secrets" {
  count = length(var.iam_policy_statements) > 0 ? 1 : 0

  compartment_id = coalesce(var.iam_policy_compartment_id, var.compartment_id)
  name           = var.iam_policy_name
  description    = var.iam_policy_description
  statements     = var.iam_policy_statements
  freeform_tags  = local.common_tags
}
