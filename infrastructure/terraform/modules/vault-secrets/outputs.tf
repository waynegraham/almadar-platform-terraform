output "vault_id" {
  description = "OCI Vault OCID."
  value       = oci_kms_vault.this.id
}

output "vault_management_endpoint" {
  description = "OCI Vault management endpoint."
  value       = oci_kms_vault.this.management_endpoint
}

output "key_id" {
  description = "OCI KMS key OCID used for secret encryption."
  value       = oci_kms_key.this.id
}

output "secret_ids" {
  description = "OCI Vault secret OCIDs keyed by logical secret key."
  value       = { for key, secret in oci_vault_secret.this : key => secret.id }
}

output "secret_names" {
  description = "OCI Vault secret names keyed by logical secret key."
  value       = { for key, secret in oci_vault_secret.this : key => secret.secret_name }
}

output "iam_policy_id" {
  description = "IAM policy OCID for External Secrets access, if created."
  value       = try(oci_identity_policy.vault_external_secrets[0].id, null)
}
