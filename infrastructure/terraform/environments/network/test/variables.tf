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
  description = "OCI compartment OCID for network resources."
  type        = string
}

variable "region" {
  description = "OCI region where the network is created."
  type        = string
  default     = "me-riyadh-1"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "almadar"
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to network resources."
  type        = map(string)
  default     = {}
}
