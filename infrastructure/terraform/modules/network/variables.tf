variable "compartment_id" {
  description = "OCID of the compartment where network resources are created."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for all network resources."
  type        = string
}

variable "region_key" {
  description = "Short region key used in names and tags."
  type        = string
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks for the VCN."
  type        = list(string)
}

variable "dns_label" {
  description = "DNS label for the VCN."
  type        = string
}

variable "subnets" {
  description = "Subnet definitions keyed by subnet name."
  type = map(object({
    cidr_block                 = string
    dns_label                  = string
    public                     = bool
    prohibit_public_ip_on_vnic = bool
  }))
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
