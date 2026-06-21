locals {
  environment = "prod"
  name_prefix = "${var.project_name}-${local.environment}"

  region_key = replace(var.region, "-", "")

  common_tags = merge(var.freeform_tags, {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  })
}

module "network" {
  source = "../../../modules/network"

  compartment_id  = var.compartment_id
  name_prefix     = local.name_prefix
  region_key      = local.region_key
  vcn_cidr_blocks = ["10.80.0.0/16"]
  dns_label       = "almadarprod"

  subnets = {
    public = {
      cidr_block                 = "10.80.0.0/24"
      dns_label                  = "public"
      public                     = true
      prohibit_public_ip_on_vnic = false
    }
    private = {
      cidr_block                 = "10.80.10.0/24"
      dns_label                  = "private"
      public                     = false
      prohibit_public_ip_on_vnic = true
    }
  }

  create_service_gateway = false
  freeform_tags          = local.common_tags
}
