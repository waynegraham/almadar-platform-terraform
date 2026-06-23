variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID used by Terraform."
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint for the OCI user."
  type        = string
}

variable "private_key_path" {
  description = "Path to the PEM private key for the OCI user."
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID for Vault resources."
  type        = string
}

variable "policy_compartment_id" {
  description = "OCI compartment OCID where IAM policies are created. Defaults to compartment_id."
  type        = string
  default     = null
}

variable "region" {
  description = "OCI region used by the provider and External Secrets SecretStore."
  type        = string
  default     = "me-riyadh-1"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "almadar"
}

variable "environments" {
  description = "Platform environments that receive secrets."
  type        = set(string)
  default     = ["dev", "test", "prod"]
}

variable "postgres_credentials" {
  description = "PostgreSQL connection credentials keyed by environment."
  type        = map(map(string))
  sensitive   = true
}

variable "s3_credentials" {
  description = "S3-compatible Object Storage credentials keyed by environment."
  type        = map(map(string))
  sensitive   = true
}

variable "jwt_secrets" {
  description = "Optional JWT secrets keyed by environment."
  type        = map(map(string))
  default     = {}
  sensitive   = true
}

variable "strapi_secrets" {
  description = "Optional Strapi secrets keyed by environment."
  type        = map(map(string))
  default     = {}
  sensitive   = true
}

variable "external_secrets_iam_policy_statements" {
  description = "IAM policy statements granting External Secrets access to Vault secrets. Use OKE workload identity or instance principal statements."
  type        = list(string)
  default     = []
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to Vault resources."
  type        = map(string)
  default     = {}
}
