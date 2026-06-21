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

variable "buckets" {
  description = "Object Storage buckets keyed by logical name."
  type = map(object({
    name                  = string
    access_type           = optional(string, "NoPublicAccess")
    storage_tier          = optional(string, "Standard")
    versioning            = optional(string, "Disabled")
    object_events_enabled = optional(bool, false)
    auto_tiering          = optional(string, "Disabled")
  }))
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
