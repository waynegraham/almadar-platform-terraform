output "db_system_ids" {
  description = "PostgreSQL DB system OCIDs keyed by logical database name."
  value       = { for name, db in oci_psql_db_system.this : name => db.id }
}

output "display_names" {
  description = "PostgreSQL DB system display names keyed by logical database name."
  value       = { for name, db in oci_psql_db_system.this : name => db.display_name }
}

output "connection_info" {
  description = "Connection information keyed by logical database name."
  sensitive   = true
  value = {
    for name, db in oci_psql_db_system.this : name => {
      database_name      = var.databases[name].database_name
      host               = try(db.network_details[0].primary_db_endpoint_private_ip, null)
      port               = 5432
      username           = var.databases[name].admin_username
      password           = try(var.admin_passwords[name], null)
      password_secret_id = try(var.admin_password_secret_ids[name], null)
      db_system_id       = db.id
    }
  }
}

output "strapi_environment" {
  description = "Strapi database environment variables keyed by logical database name."
  sensitive   = true
  value = {
    for name, db in oci_psql_db_system.this : name => {
      DATABASE_CLIENT                  = "postgres"
      DATABASE_HOST                    = try(db.network_details[0].primary_db_endpoint_private_ip, null)
      DATABASE_PORT                    = "5432"
      DATABASE_NAME                    = var.databases[name].database_name
      DATABASE_USERNAME                = var.databases[name].admin_username
      DATABASE_PASSWORD                = try(var.admin_passwords[name], null)
      DATABASE_SSL                     = "true"
      DATABASE_SSL_REJECT_UNAUTHORIZED = "false"
    }
  }
}
