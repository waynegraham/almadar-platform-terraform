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
  description = "OCI compartment OCID where PostgreSQL DB systems are created."
  type        = string
}

variable "region" {
  description = "OCI region used by the provider."
  type        = string
  default     = "me-riyadh-1"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "almadar"
}

variable "database_subnet_ids" {
  description = "Private subnet OCIDs for PostgreSQL DB systems keyed by dev, test, and prod."
  type = object({
    dev  = string
    test = string
    prod = string
  })
}

variable "database_nsg_ids" {
  description = "Network Security Group OCIDs for PostgreSQL DB systems keyed by dev, test, and prod."
  type = object({
    dev  = optional(list(string), [])
    test = optional(list(string), [])
    prod = optional(list(string), [])
  })
  default = {}
}

variable "admin_username" {
  description = "PostgreSQL administrator username used by Strapi."
  type        = string
  default     = "strapi_admin"
}

variable "admin_passwords" {
  description = "Plaintext PostgreSQL administrator passwords keyed by dev, test, and prod. Prefer admin_password_secret_ids for shared environments."
  type = object({
    dev  = optional(string)
    test = optional(string)
    prod = optional(string)
  })
  default   = {}
  sensitive = true
}

variable "admin_password_secret_ids" {
  description = "OCI Vault secret OCIDs for PostgreSQL administrator passwords keyed by dev, test, and prod."
  type = object({
    dev  = optional(string)
    test = optional(string)
    prod = optional(string)
  })
  default = {}
}

variable "shape" {
  description = "PostgreSQL DB system shape."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_ocpu_count" {
  description = "OCPUs per PostgreSQL DB system instance."
  type        = number
  default     = 2
}

variable "instance_memory_size_in_gbs" {
  description = "Memory in GB per PostgreSQL DB system instance."
  type        = number
  default     = 16
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 14
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to PostgreSQL resources."
  type        = map(string)
  default     = {}
}
