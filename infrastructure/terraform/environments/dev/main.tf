locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.freeform_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  regions = {
    riyadh = {
      region     = "me-riyadh-1"
      region_key = "riyadh"
      dns_label  = "almadarruh"
      vcn_cidrs  = ["10.40.0.0/16"]
      subnets = {
        public_lb = {
          cidr_block                 = "10.40.0.0/24"
          dns_label                  = "publb"
          public                     = true
          prohibit_public_ip_on_vnic = false
        }
        private_workers = {
          cidr_block                 = "10.40.10.0/24"
          dns_label                  = "workers"
          public                     = false
          prohibit_public_ip_on_vnic = true
        }
        private_data = {
          cidr_block                 = "10.40.20.0/24"
          dns_label                  = "data"
          public                     = false
          prohibit_public_ip_on_vnic = true
        }
      }
    }
    jeddah = {
      region     = "me-jeddah-1"
      region_key = "jeddah"
      dns_label  = "almadarjed"
      vcn_cidrs  = ["10.50.0.0/16"]
      subnets = {
        public_lb = {
          cidr_block                 = "10.50.0.0/24"
          dns_label                  = "publb"
          public                     = true
          prohibit_public_ip_on_vnic = false
        }
        private_workers = {
          cidr_block                 = "10.50.10.0/24"
          dns_label                  = "workers"
          public                     = false
          prohibit_public_ip_on_vnic = true
        }
        private_data = {
          cidr_block                 = "10.50.20.0/24"
          dns_label                  = "data"
          public                     = false
          prohibit_public_ip_on_vnic = true
        }
      }
    }
  }

  buckets = {
    riyadh = {
      iiif = {
        name       = "${local.name_prefix}-riyadh-iiif"
        versioning = "Enabled"
      }
      strapi = {
        name       = "${local.name_prefix}-riyadh-strapi"
        versioning = "Enabled"
      }
    }
    jeddah = {
      iiif = {
        name       = "${local.name_prefix}-jeddah-iiif"
        versioning = "Enabled"
      }
      strapi = {
        name       = "${local.name_prefix}-jeddah-strapi"
        versioning = "Enabled"
      }
    }
  }
}

module "network_riyadh" {
  source = "../../modules/network"

  providers = {
    oci = oci.riyadh
  }

  compartment_id         = var.compartment_id
  name_prefix            = local.name_prefix
  region_key             = local.regions.riyadh.region_key
  vcn_cidr_blocks        = local.regions.riyadh.vcn_cidrs
  dns_label              = local.regions.riyadh.dns_label
  subnets                = local.regions.riyadh.subnets
  create_service_gateway = var.create_service_gateway
  freeform_tags          = local.common_tags
}

module "network_jeddah" {
  source = "../../modules/network"

  providers = {
    oci = oci.jeddah
  }

  compartment_id         = var.compartment_id
  name_prefix            = local.name_prefix
  region_key             = local.regions.jeddah.region_key
  vcn_cidr_blocks        = local.regions.jeddah.vcn_cidrs
  dns_label              = local.regions.jeddah.dns_label
  subnets                = local.regions.jeddah.subnets
  create_service_gateway = var.create_service_gateway
  freeform_tags          = local.common_tags
}

module "object_storage_riyadh" {
  source = "../../modules/object-storage"

  providers = {
    oci = oci.riyadh
  }

  compartment_id = var.compartment_id
  name_prefix    = local.name_prefix
  region_key     = local.regions.riyadh.region_key
  namespace      = var.object_storage_namespace
  buckets        = local.buckets.riyadh
  freeform_tags  = local.common_tags
}

module "object_storage_jeddah" {
  source = "../../modules/object-storage"

  providers = {
    oci = oci.jeddah
  }

  compartment_id = var.compartment_id
  name_prefix    = local.name_prefix
  region_key     = local.regions.jeddah.region_key
  namespace      = var.object_storage_namespace
  buckets        = local.buckets.jeddah
  freeform_tags  = local.common_tags
}

module "kubernetes_riyadh" {
  source = "../../modules/kubernetes"

  providers = {
    oci = oci.riyadh
  }

  compartment_id        = var.compartment_id
  name_prefix           = local.name_prefix
  region_key            = local.regions.riyadh.region_key
  vcn_id                = module.network_riyadh.vcn_id
  endpoint_subnet_id    = module.network_riyadh.private_subnet_ids["private_workers"]
  service_lb_subnet_ids = [module.network_riyadh.public_subnet_ids["public_lb"]]
  worker_subnet_id      = module.network_riyadh.private_subnet_ids["private_workers"]
  nsg_ids               = [module.network_riyadh.oke_nsg_id]
  kubernetes_version    = var.kubernetes_version
  create_node_pool      = var.create_node_pool
  node_image_id         = try(var.node_image_ids.riyadh, null)
  availability_domain   = try(var.node_pool_availability_domains.riyadh, null)
  ssh_public_key        = var.ssh_public_key
  freeform_tags         = local.common_tags
}

module "kubernetes_jeddah" {
  source = "../../modules/kubernetes"

  providers = {
    oci = oci.jeddah
  }

  compartment_id        = var.compartment_id
  name_prefix           = local.name_prefix
  region_key            = local.regions.jeddah.region_key
  vcn_id                = module.network_jeddah.vcn_id
  endpoint_subnet_id    = module.network_jeddah.private_subnet_ids["private_workers"]
  service_lb_subnet_ids = [module.network_jeddah.public_subnet_ids["public_lb"]]
  worker_subnet_id      = module.network_jeddah.private_subnet_ids["private_workers"]
  nsg_ids               = [module.network_jeddah.oke_nsg_id]
  kubernetes_version    = var.kubernetes_version
  create_node_pool      = var.create_node_pool
  node_image_id         = try(var.node_image_ids.jeddah, null)
  availability_domain   = try(var.node_pool_availability_domains.jeddah, null)
  ssh_public_key        = var.ssh_public_key
  freeform_tags         = local.common_tags
}

module "postgresql_riyadh" {
  source = "../../modules/managed-postgresql"

  providers = {
    oci = oci.riyadh
  }

  compartment_id = var.compartment_id
  name_prefix    = "${local.name_prefix}-${local.regions.riyadh.region_key}"
  databases = try(nonsensitive(var.postgresql.enabled), false) ? {
    (var.environment) = {
      database_name               = "strapi_${var.environment}"
      subnet_id                   = module.network_riyadh.private_subnet_ids["private_data"]
      nsg_ids                     = [module.network_riyadh.postgresql_nsg_id]
      db_version                  = try(nonsensitive(var.postgresql.db_version), "16")
      admin_username              = try(nonsensitive(var.postgresql.admin_username), "almadar_admin")
      shape                       = try(nonsensitive(var.postgresql.shape), "VM.Standard.E4.Flex")
      instance_count              = try(nonsensitive(var.postgresql.instance_count), 1)
      instance_ocpu_count         = try(nonsensitive(var.postgresql.instance_ocpu_count), 2)
      instance_memory_size_in_gbs = try(nonsensitive(var.postgresql.instance_memory_size_in_gbs), 16)
      backup_retention_days       = try(nonsensitive(var.postgresql.backup_retention_days), 14)
      description                 = "OCI Database with PostgreSQL managed DB system for Strapi ${var.environment} in ${local.regions.riyadh.region}."
    }
  } : {}
  admin_passwords = try(nonsensitive(var.postgresql.enabled), false) ? {
    (var.environment) = var.postgresql.admin_password
  } : {}
  freeform_tags = merge(local.common_tags, {
    Region = local.regions.riyadh.region_key
  })
}

module "postgresql_jeddah" {
  source = "../../modules/managed-postgresql"

  providers = {
    oci = oci.jeddah
  }

  compartment_id = var.compartment_id
  name_prefix    = "${local.name_prefix}-${local.regions.jeddah.region_key}"
  databases = try(nonsensitive(var.postgresql.enabled), false) ? {
    (var.environment) = {
      database_name               = "strapi_${var.environment}"
      subnet_id                   = module.network_jeddah.private_subnet_ids["private_data"]
      nsg_ids                     = [module.network_jeddah.postgresql_nsg_id]
      db_version                  = try(nonsensitive(var.postgresql.db_version), "16")
      admin_username              = try(nonsensitive(var.postgresql.admin_username), "almadar_admin")
      shape                       = try(nonsensitive(var.postgresql.shape), "VM.Standard.E4.Flex")
      instance_count              = try(nonsensitive(var.postgresql.instance_count), 1)
      instance_ocpu_count         = try(nonsensitive(var.postgresql.instance_ocpu_count), 2)
      instance_memory_size_in_gbs = try(nonsensitive(var.postgresql.instance_memory_size_in_gbs), 16)
      backup_retention_days       = try(nonsensitive(var.postgresql.backup_retention_days), 14)
      description                 = "OCI Database with PostgreSQL managed DB system for Strapi ${var.environment} in ${local.regions.jeddah.region}."
    }
  } : {}
  admin_passwords = try(nonsensitive(var.postgresql.enabled), false) ? {
    (var.environment) = var.postgresql.admin_password
  } : {}
  freeform_tags = merge(local.common_tags, {
    Region = local.regions.jeddah.region_key
  })
}
