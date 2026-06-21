output "db_system_ids" {
  description = "PostgreSQL DB system OCIDs keyed by dev, test, and prod."
  value       = module.postgresql.db_system_ids
}

output "display_names" {
  description = "PostgreSQL DB system display names keyed by dev, test, and prod."
  value       = module.postgresql.display_names
}

output "connection_info" {
  description = "Connection information keyed by dev, test, and prod."
  value       = module.postgresql.connection_info
  sensitive   = true
}

output "strapi_environment" {
  description = "Strapi database environment variables keyed by dev, test, and prod."
  value       = module.postgresql.strapi_environment
  sensitive   = true
}
