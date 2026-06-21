variable "compartment_id" {
  description = "OCI compartment OCID for the vault, key, and secrets."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for Vault resources."
  type        = string
}

variable "vault_type" {
  description = "OCI Vault type."
  type        = string
  default     = "DEFAULT"
}

variable "secrets" {
  description = "Secret metadata keyed by logical secret key."
  type = map(object({
    secret_name = string
    description = string
  }))
}

variable "secret_payloads" {
  description = "Secret JSON payloads keyed by logical secret key."
  type        = map(any)
  sensitive   = true
}

variable "iam_policy_compartment_id" {
  description = "Compartment OCID where IAM policy is created."
  type        = string
  default     = null
}

variable "iam_policy_name" {
  description = "IAM policy name for Vault secret access."
  type        = string
  default     = null
}

variable "iam_policy_description" {
  description = "IAM policy description for Vault secret access."
  type        = string
  default     = null
}

variable "iam_policy_statements" {
  description = "IAM policy statements granting External Secrets access to Vault secrets."
  type        = list(string)
  default     = []
}

variable "freeform_tags" {
  description = "Freeform tags applied to Vault resources."
  type        = map(string)
  default     = {}
}
