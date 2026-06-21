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
  description = "OCI compartment OCID where buckets are created."
  type        = string
}

variable "policy_compartment_id" {
  description = "OCI compartment OCID where IAM policies are created. Defaults to compartment_id."
  type        = string
  default     = null
}

variable "region" {
  description = "OCI region used by the provider."
  type        = string
  default     = "me-riyadh-1"
}

variable "object_storage_namespace" {
  description = "OCI Object Storage namespace for the tenancy."
  type        = string
}

variable "project_name" {
  description = "Project name used in tags and policy names."
  type        = string
  default     = "almadar"
}

variable "object_storage_admin_group_name" {
  description = "OCI IAM group granted bucket and object management permissions."
  type        = string
}

variable "object_storage_writer_group_name" {
  description = "OCI IAM group granted object write permissions for all platform buckets."
  type        = string
}

variable "object_storage_reader_group_name" {
  description = "OCI IAM group granted object read permissions for all platform buckets."
  type        = string
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to Object Storage resources."
  type        = map(string)
  default     = {}
}
