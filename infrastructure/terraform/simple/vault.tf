resource "oci_kms_vault" "this" {
  count = var.enable_vault ? 1 : 0

  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-vault"
  vault_type     = var.vault_type
  freeform_tags  = local.common_tags
}

resource "oci_kms_key" "this" {
  count = var.enable_vault ? 1 : 0

  compartment_id      = local.compartment_id
  display_name        = "${local.name_prefix}-secrets-key"
  management_endpoint = oci_kms_vault.this[0].management_endpoint
  freeform_tags       = local.common_tags

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "postgres_admin_password" {
  count = var.enable_vault ? 1 : 0

  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.this[0].id
  key_id         = oci_kms_key.this[0].id
  secret_name    = "${local.name_prefix}-postgres-admin-password"
  description    = "PostgreSQL administrator password for the simplified launch stack."
  freeform_tags  = local.common_tags

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.postgres_admin_password)
    stage        = "CURRENT"
  }
}

resource "oci_vault_secret" "additional" {
  for_each = var.enable_vault ? toset(nonsensitive(keys(var.additional_secret_payloads))) : []

  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.this[0].id
  key_id         = oci_kms_key.this[0].id
  secret_name    = "${local.name_prefix}-${each.value}"
  description    = "Optional launch secret ${each.value}."
  freeform_tags  = local.common_tags

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.additional_secret_payloads[each.value])
    stage        = "CURRENT"
  }
}
