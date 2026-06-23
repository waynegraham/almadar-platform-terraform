variable "compartment_id" {
  description = "OCID of the compartment where buckets are created."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for buckets."
  type        = string
}

variable "region_key" {
  description = "Short region key used in names and tags."
  type        = string
}

variable "namespace" {
  description = "OCI Object Storage namespace for the tenancy."
  type        = string
}

variable "buckets" {
  description = "Object Storage buckets keyed by logical name."
  type = map(object({
    name                  = string
    access_type           = optional(string, "NoPublicAccess")
    storage_tier          = optional(string, "Standard")
    versioning            = optional(string, "Disabled")
    object_events_enabled = optional(bool, false)
    auto_tiering          = optional(string, "Disabled")
    lifecycle_rules = optional(list(object({
      name        = string
      action      = string
      time_amount = number
      is_enabled  = optional(bool, true)
      target      = optional(string, "objects")
      time_unit   = optional(string, "DAYS")
      object_name_filter = optional(object({
        exclusion_patterns = optional(list(string), [])
        inclusion_patterns = optional(list(string), [])
        inclusion_prefixes = optional(list(string), [])
      }), null)
    })), [])
  }))
}

variable "iam_policy_compartment_id" {
  description = "Compartment OCID where the Object Storage IAM policy is created."
  type        = string
  default     = null
}

variable "iam_policy_name" {
  description = "Name for the Object Storage IAM policy."
  type        = string
  default     = null
}

variable "iam_policy_description" {
  description = "Description for the Object Storage IAM policy."
  type        = string
  default     = null
}

variable "iam_policy_statements" {
  description = "IAM policy statements for Object Storage bucket access."
  type        = list(string)
  default     = []
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
