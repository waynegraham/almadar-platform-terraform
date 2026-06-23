variable "compartment_id" {
  description = "OCID of the compartment where PostgreSQL DB systems are created."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for PostgreSQL resources."
  type        = string
}

variable "databases" {
  description = "Managed PostgreSQL DB systems keyed by logical database name."
  type = map(object({
    database_name               = string
    subnet_id                   = string
    nsg_ids                     = optional(list(string), [])
    db_version                  = optional(string, "16")
    admin_username              = optional(string, "strapi_admin")
    shape                       = optional(string, "VM.Standard.E4.Flex")
    instance_count              = optional(number, 1)
    instance_ocpu_count         = optional(number, 2)
    instance_memory_size_in_gbs = optional(number, 16)
    storage_system_type         = optional(string, "OCI_OPTIMIZED_STORAGE")
    storage_iops                = optional(number)
    is_regionally_durable       = optional(bool, true)
    availability_domain         = optional(string)
    backup_retention_days       = optional(number, 14)
    backup_start_hour           = optional(string, "02:00")
    maintenance_window_start    = optional(string, "sun 03:00")
    description                 = optional(string)
    private_ip                  = optional(string)
    reader_endpoint_enabled     = optional(bool, false)
  }))
}

variable "admin_passwords" {
  description = "Plaintext administrator passwords keyed by database key."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "admin_password_secret_ids" {
  description = "OCI Vault secret OCIDs for administrator passwords keyed by database key."
  type        = map(string)
  default     = {}
}

variable "admin_password_secret_versions" {
  description = "OCI Vault secret versions for administrator passwords keyed by database key."
  type        = map(number)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
