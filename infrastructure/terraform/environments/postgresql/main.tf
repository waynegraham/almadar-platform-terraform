locals {
  name_prefix = "${var.project_name}-strapi"

  common_tags = merge(var.freeform_tags, {
    Project   = var.project_name
    Component = "strapi"
  })

  strapi_databases = {
    dev = {
      database_name               = "strapi_dev"
      subnet_id                   = var.database_subnet_ids.dev
      nsg_ids                     = var.database_nsg_ids.dev
      admin_username              = var.admin_username
      shape                       = var.shape
      instance_ocpu_count         = var.instance_ocpu_count
      instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
      backup_retention_days       = var.backup_retention_days
      description                 = "Managed PostgreSQL database system for Strapi dev."
    }
    test = {
      database_name               = "strapi_test"
      subnet_id                   = var.database_subnet_ids.test
      nsg_ids                     = var.database_nsg_ids.test
      admin_username              = var.admin_username
      shape                       = var.shape
      instance_ocpu_count         = var.instance_ocpu_count
      instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
      backup_retention_days       = var.backup_retention_days
      description                 = "Managed PostgreSQL database system for Strapi test."
    }
    prod = {
      database_name               = "strapi_prod"
      subnet_id                   = var.database_subnet_ids.prod
      nsg_ids                     = var.database_nsg_ids.prod
      admin_username              = var.admin_username
      shape                       = var.shape
      instance_ocpu_count         = var.instance_ocpu_count
      instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
      backup_retention_days       = var.backup_retention_days
      description                 = "Managed PostgreSQL database system for Strapi prod."
    }
  }
}

module "postgresql" {
  source = "../../modules/managed-postgresql"

  compartment_id = var.compartment_id
  name_prefix    = local.name_prefix
  databases      = local.strapi_databases
  admin_passwords = {
    for key, value in var.admin_passwords : key => value
    if value != null
  }
  admin_password_secret_ids = {
    for key, value in var.admin_password_secret_ids : key => value
    if value != null
  }
  freeform_tags = local.common_tags
}
