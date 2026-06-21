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
  description = "OCI compartment OCID for platform resources."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "almadar"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version for both regions."
  type        = string
  default     = "v1.33.1"
}

variable "create_node_pool" {
  description = "Create OKE managed node pools."
  type        = bool
  default     = false
}

variable "node_image_ids" {
  description = "OKE worker image OCIDs keyed by region key. Required when create_node_pool is true."
  type = object({
    riyadh = optional(string)
    jeddah = optional(string)
  })
  default = {}
}

variable "node_pool_availability_domains" {
  description = "Node pool availability domains keyed by region key. Required when create_node_pool is true."
  type = object({
    riyadh = optional(string)
    jeddah = optional(string)
  })
  default = {}
}

variable "ssh_public_key" {
  description = "SSH public key for OKE worker nodes. Required when create_node_pool is true."
  type        = string
  default     = null
}

variable "postgresql" {
  description = "PostgreSQL configuration."
  type = object({
    enabled                     = optional(bool, false)
    admin_username              = optional(string, "almadar_admin")
    admin_password              = optional(string)
    db_version                  = optional(string, "16")
    shape                       = optional(string, "VM.Standard.E4.Flex")
    instance_count              = optional(number, 1)
    instance_ocpu_count         = optional(number, 2)
    instance_memory_size_in_gbs = optional(number, 16)
    backup_retention_days       = optional(number, 14)
  })
  default   = {}
  sensitive = true
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to all resources."
  type        = map(string)
  default     = {}
}
