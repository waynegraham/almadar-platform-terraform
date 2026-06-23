output "compartment_id" {
  description = "Compartment OCID used by the simplified stack."
  value       = local.compartment_id
}

output "vcn_id" {
  description = "Launch VCN OCID."
  value       = oci_core_vcn.this.id
}

output "subnet_ids" {
  description = "Subnet OCIDs."
  value = {
    app      = oci_core_subnet.app.id
    runner   = oci_core_subnet.runner.id
    database = oci_core_subnet.database.id
  }
}

output "network_security_group_ids" {
  description = "Network Security Group OCIDs."
  value = {
    app        = oci_core_network_security_group.app.id
    runner     = oci_core_network_security_group.runner.id
    postgresql = oci_core_network_security_group.postgresql.id
  }
}

output "app_server" {
  description = "Application VM connection details."
  value = {
    id         = oci_core_instance.app.id
    private_ip = oci_core_instance.app.private_ip
    public_ip  = oci_core_instance.app.public_ip
  }
}

output "runner_server" {
  description = "GitHub runner VM connection details."
  value = {
    id         = oci_core_instance.runner.id
    private_ip = oci_core_instance.runner.private_ip
    public_ip  = oci_core_instance.runner.public_ip
  }
}

output "postgresql" {
  description = "Managed PostgreSQL connection metadata."
  sensitive   = true
  value = {
    id            = oci_psql_db_system.strapi.id
    database_name = var.postgres_database_name
    host          = try(oci_psql_db_system.strapi.network_details[0].primary_db_endpoint_private_ip, null)
    port          = 5432
    username      = var.postgres_admin_username
    password      = var.enable_vault ? null : var.postgres_admin_password
  }
}

output "object_storage" {
  description = "Object Storage namespace and bucket names."
  value = {
    namespace      = data.oci_objectstorage_namespace.this.namespace
    strapi_uploads = oci_objectstorage_bucket.strapi_uploads.name
    iiif_sources   = oci_objectstorage_bucket.iiif_sources.name
    backups        = oci_objectstorage_bucket.backups.name
  }
}

output "vault" {
  description = "Vault resources when enable_vault is true."
  value = var.enable_vault ? {
    vault_id                 = oci_kms_vault.this[0].id
    key_id                   = oci_kms_key.this[0].id
    postgres_password_secret = oci_vault_secret.postgres_admin_password[0].id
    additional_secret_ids    = { for key, secret in oci_vault_secret.additional : key => secret.id }
  } : null
}

output "strapi_database_environment" {
  description = "Database environment values for production Compose."
  sensitive   = true
  value = {
    DATABASE_CLIENT   = "postgres"
    DATABASE_HOST     = try(oci_psql_db_system.strapi.network_details[0].primary_db_endpoint_private_ip, null)
    DATABASE_PORT     = "5432"
    DATABASE_NAME     = var.postgres_database_name
    DATABASE_USERNAME = var.postgres_admin_username
    DATABASE_PASSWORD = var.enable_vault ? null : var.postgres_admin_password
    DATABASE_SSL      = "true"
  }
}
