variable "enabled" {
  description = "Create the PostgreSQL DB system."
  type        = bool
  default     = false
}

variable "compartment_id" {
  description = "OCID of the compartment where PostgreSQL is created."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for PostgreSQL resources."
  type        = string
}

variable "region_key" {
  description = "Short region key used in names and tags."
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID for the PostgreSQL private endpoint."
  type        = string
}

variable "nsg_ids" {
  description = "NSG OCIDs applied to the PostgreSQL DB system."
  type        = list(string)
  default     = []
}

variable "db_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "admin_username" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "almadar_admin"
}

variable "admin_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
  default     = null
}

variable "shape" {
  description = "PostgreSQL DB system shape."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_count" {
  description = "Number of PostgreSQL instances."
  type        = number
  default     = 1
}

variable "instance_ocpu_count" {
  description = "OCPUs per PostgreSQL instance."
  type        = number
  default     = 2
}

variable "instance_memory_size_in_gbs" {
  description = "Memory in GB per PostgreSQL instance."
  type        = number
  default     = 16
}

variable "storage_system_type" {
  description = "PostgreSQL storage system type."
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
}

variable "is_regionally_durable" {
  description = "Use regional durable block storage."
  type        = bool
  default     = true
}

variable "availability_domain" {
  description = "Availability domain for AD-local storage. Leave null when is_regionally_durable is true."
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 14
}

variable "backup_start_hour" {
  description = "UTC hour when daily backups start."
  type        = string
  default     = "02:00"
}

variable "maintenance_window_start" {
  description = "Maintenance window start in OCI format, for example sun 03:00."
  type        = string
  default     = "sun 03:00"
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
