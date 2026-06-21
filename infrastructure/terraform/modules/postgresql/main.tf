locals {
  common_tags = merge(var.freeform_tags, {
    Region = var.region_key
  })
}

resource "oci_psql_db_system" "this" {
  count = var.enabled ? 1 : 0

  compartment_id = var.compartment_id
  db_version     = var.db_version
  display_name   = "${var.name_prefix}-${var.region_key}-postgresql"
  shape          = var.shape
  freeform_tags  = local.common_tags

  credentials {
    username = var.admin_username

    password_details {
      password_type = "PLAIN_TEXT"
      password      = var.admin_password
    }
  }

  network_details {
    subnet_id = var.subnet_id
    nsg_ids   = var.nsg_ids
  }

  storage_details {
    is_regionally_durable = var.is_regionally_durable
    system_type           = var.storage_system_type
    availability_domain   = var.availability_domain
  }

  instance_count              = var.instance_count
  instance_ocpu_count         = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs

  management_policy {
    backup_policy {
      kind           = "DAILY"
      backup_start   = var.backup_start_hour
      retention_days = var.backup_retention_days
    }

    maintenance_window_start = var.maintenance_window_start
  }

  lifecycle {
    precondition {
      condition     = !var.enabled || var.admin_password != null
      error_message = "admin_password is required when PostgreSQL is enabled."
    }
  }
}
