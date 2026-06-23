locals {
  common_tags = merge(var.freeform_tags, {
    ManagedBy = "terraform"
  })
}

resource "oci_psql_db_system" "this" {
  for_each = var.databases

  compartment_id = var.compartment_id
  db_version     = each.value.db_version
  description    = coalesce(each.value.description, "Managed PostgreSQL for ${each.value.database_name}.")
  display_name   = "${var.name_prefix}-${replace(each.value.database_name, "_", "-")}"
  shape          = each.value.shape
  freeform_tags = merge(local.common_tags, {
    DatabaseName = each.value.database_name
  })

  credentials {
    username = each.value.admin_username

    password_details {
      password_type  = try(var.admin_password_secret_ids[each.key], null) == null ? "PLAIN_TEXT" : "VAULT_SECRET"
      password       = try(var.admin_passwords[each.key], null)
      secret_id      = try(var.admin_password_secret_ids[each.key], null)
      secret_version = try(var.admin_password_secret_versions[each.key], null)
    }
  }

  network_details {
    subnet_id                      = each.value.subnet_id
    nsg_ids                        = each.value.nsg_ids
    primary_db_endpoint_private_ip = each.value.private_ip
    is_reader_endpoint_enabled     = each.value.reader_endpoint_enabled
  }

  storage_details {
    is_regionally_durable = each.value.is_regionally_durable
    system_type           = each.value.storage_system_type
    availability_domain   = each.value.availability_domain
    iops                  = each.value.storage_iops
  }

  instance_count              = each.value.instance_count
  instance_ocpu_count         = each.value.instance_ocpu_count
  instance_memory_size_in_gbs = each.value.instance_memory_size_in_gbs

  management_policy {
    backup_policy {
      kind           = "DAILY"
      backup_start   = each.value.backup_start_hour
      retention_days = each.value.backup_retention_days
    }

    maintenance_window_start = each.value.maintenance_window_start
  }

  lifecycle {
    precondition {
      condition = (
        try(var.admin_passwords[each.key], null) != null ||
        try(var.admin_password_secret_ids[each.key], null) != null
      )
      error_message = "Each PostgreSQL DB system requires admin_password or admin_password_secret_id."
    }
  }
}
