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

variable "region" {
  description = "OCI region for the simplified launch stack."
  type        = string
  default     = "me-riyadh-1"
}

variable "compartment_id" {
  description = "OCI compartment OCID. If null, compartment_name is used for lookup."
  type        = string
  default     = null
}

variable "compartment_name" {
  description = "OCI compartment name used when compartment_id is null."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "almadar"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"
}

variable "availability_domain" {
  description = "Availability domain for VMs and block volumes. Defaults to the first AD in the compartment."
  type        = string
  default     = null
}

variable "vcn_cidr" {
  description = "CIDR block for the launch VCN."
  type        = string
  default     = "10.40.0.0/16"
}

variable "app_subnet_cidr" {
  description = "Public subnet CIDR for the app server VM."
  type        = string
  default     = "10.40.10.0/24"
}

variable "runner_subnet_cidr" {
  description = "Public subnet CIDR for the GitHub runner VM."
  type        = string
  default     = "10.40.20.0/24"
}

variable "database_subnet_cidr" {
  description = "Private subnet CIDR for managed PostgreSQL."
  type        = string
  default     = "10.40.30.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key installed on both VMs."
  type        = string
}

variable "ssh_source_cidrs" {
  description = "CIDR blocks allowed to SSH to the app and runner VMs."
  type        = list(string)
  default     = []
}

variable "http_source_cidrs" {
  description = "CIDR blocks allowed to reach HTTP/HTTPS on the app VM. Prefer Cloudflare origin CIDRs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_instance_shape" {
  description = "OCI shape for the app server VM."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "app_ocpus" {
  description = "OCPUs for the app server VM."
  type        = number
  default     = 4
}

variable "app_memory_gbs" {
  description = "Memory in GB for the app server VM."
  type        = number
  default     = 32
}

variable "app_boot_volume_gbs" {
  description = "Boot volume size in GB for the app server VM."
  type        = number
  default     = 100
}

variable "app_data_volume_gbs" {
  description = "Block volume size in GB for Docker data, logs, and Cantaloupe cache."
  type        = number
  default     = 200
}

variable "runner_instance_shape" {
  description = "OCI shape for the GitHub runner VM."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "runner_ocpus" {
  description = "OCPUs for the GitHub runner VM."
  type        = number
  default     = 2
}

variable "runner_memory_gbs" {
  description = "Memory in GB for the GitHub runner VM."
  type        = number
  default     = 16
}

variable "runner_boot_volume_gbs" {
  description = "Boot volume size in GB for the GitHub runner VM."
  type        = number
  default     = 100
}

variable "instance_image_operating_system" {
  description = "Operating system filter for OCI platform images."
  type        = string
  default     = "Oracle Linux"
}

variable "instance_image_operating_system_version" {
  description = "Operating system version filter for OCI platform images."
  type        = string
  default     = "9"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username used by Strapi."
  type        = string
  default     = "strapi_admin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password. Prefer passing by TF_VAR or a local tfvars file that is not committed."
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Logical PostgreSQL database name used by Strapi."
  type        = string
  default     = "strapi"
}

variable "postgres_db_version" {
  description = "OCI Database with PostgreSQL version."
  type        = string
  default     = "16"
}

variable "postgres_shape" {
  description = "OCI Database with PostgreSQL DB system shape."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "postgres_instance_count" {
  description = "Number of PostgreSQL instances."
  type        = number
  default     = 1
}

variable "postgres_ocpus" {
  description = "OCPUs for the PostgreSQL DB system instance."
  type        = number
  default     = 2
}

variable "postgres_memory_gbs" {
  description = "Memory in GB for the PostgreSQL DB system instance."
  type        = number
  default     = 16
}

variable "postgres_backup_retention_days" {
  description = "PostgreSQL backup retention in days."
  type        = number
  default     = 14
}

variable "postgres_backup_start_hour" {
  description = "PostgreSQL daily backup start time in UTC HH:MM format."
  type        = string
  default     = "02:00"
}

variable "postgres_maintenance_window_start" {
  description = "PostgreSQL maintenance window start, for example sun 03:00."
  type        = string
  default     = "sun 03:00"
}

variable "bucket_names" {
  description = "Optional explicit Object Storage bucket names."
  type = object({
    strapi_uploads = optional(string)
    iiif_sources   = optional(string)
    backups        = optional(string)
  })
  default = {}
}

variable "bucket_versioning" {
  description = "Versioning mode for Object Storage buckets."
  type        = string
  default     = "Enabled"
}

variable "backup_previous_version_retention_days" {
  description = "Days to retain previous object versions in the backups bucket."
  type        = number
  default     = 180
}

variable "enable_vault" {
  description = "Create an OCI Vault, KMS key, and launch secrets."
  type        = bool
  default     = false
}

variable "vault_type" {
  description = "OCI Vault type."
  type        = string
  default     = "DEFAULT"
}

variable "additional_secret_payloads" {
  description = "Additional optional secrets to store in OCI Vault when enable_vault is true."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
