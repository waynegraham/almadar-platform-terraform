output "db_system_id" {
  description = "PostgreSQL DB system OCID, if created."
  value       = try(oci_psql_db_system.this[0].id, null)
}

output "display_name" {
  description = "PostgreSQL DB system display name, if created."
  value       = try(oci_psql_db_system.this[0].display_name, null)
}
