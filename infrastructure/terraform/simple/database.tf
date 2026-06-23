resource "oci_psql_db_system" "strapi" {
  compartment_id = local.compartment_id
  db_version     = var.postgres_db_version
  description    = "Managed PostgreSQL for AlMadar Strapi."
  display_name   = "${local.name_prefix}-${var.postgres_database_name}-postgresql"
  shape          = var.postgres_shape
  freeform_tags  = local.common_tags

  credentials {
    username = var.postgres_admin_username

    password_details {
      password_type  = var.enable_vault ? "VAULT_SECRET" : "PLAIN_TEXT"
      password       = var.enable_vault ? null : var.postgres_admin_password
      secret_id      = var.enable_vault ? oci_vault_secret.postgres_admin_password[0].id : null
      secret_version = null
    }
  }

  network_details {
    subnet_id                  = oci_core_subnet.database.id
    nsg_ids                    = [oci_core_network_security_group.postgresql.id]
    is_reader_endpoint_enabled = false
  }

  storage_details {
    is_regionally_durable = true
    system_type           = "OCI_OPTIMIZED_STORAGE"
  }

  instance_count              = var.postgres_instance_count
  instance_ocpu_count         = var.postgres_ocpus
  instance_memory_size_in_gbs = var.postgres_memory_gbs

  management_policy {
    backup_policy {
      kind           = "DAILY"
      backup_start   = var.postgres_backup_start_hour
      retention_days = var.postgres_backup_retention_days
    }

    maintenance_window_start = var.postgres_maintenance_window_start
  }
}
