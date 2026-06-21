output "vault_id" {
  description = "OCI Vault OCID."
  value       = module.vault_secrets.vault_id
}

output "key_id" {
  description = "OCI KMS key OCID."
  value       = module.vault_secrets.key_id
}

output "secret_names" {
  description = "OCI Vault secret names keyed by logical secret key."
  value       = module.vault_secrets.secret_names
}

output "secret_ids" {
  description = "OCI Vault secret OCIDs keyed by logical secret key."
  value       = module.vault_secrets.secret_ids
}

output "iam_policy_id" {
  description = "IAM policy OCID for External Secrets access, if created."
  value       = module.vault_secrets.iam_policy_id
}
