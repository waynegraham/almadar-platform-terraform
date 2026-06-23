locals {
  sorted_environments = sort(tolist(var.environments))

  secret_definitions = merge(
    {
      for env in local.sorted_environments : "postgres-${env}" => {
        secret_name = "${var.project_name}-${env}-postgres"
        description = "PostgreSQL credentials for ${env}."
      }
    },
    {
      for env in local.sorted_environments : "jwt-${env}" => {
        secret_name = "${var.project_name}-${env}-jwt"
        description = "JWT secrets for ${env}."
      }
    },
    {
      for env in local.sorted_environments : "strapi-${env}" => {
        secret_name = "${var.project_name}-${env}-strapi"
        description = "Strapi application secrets for ${env}."
      }
    },
    {
      for env in local.sorted_environments : "s3-${env}" => {
        secret_name = "${var.project_name}-${env}-s3"
        description = "S3-compatible Object Storage credentials for ${env}."
      }
    }
  )

  secret_payloads = merge(
    {
      for env in local.sorted_environments : "postgres-${env}" => {
        DATABASE_CLIENT                  = lookup(var.postgres_credentials[env], "DATABASE_CLIENT", "postgres")
        DATABASE_HOST                    = var.postgres_credentials[env].DATABASE_HOST
        DATABASE_PORT                    = lookup(var.postgres_credentials[env], "DATABASE_PORT", "5432")
        DATABASE_NAME                    = var.postgres_credentials[env].DATABASE_NAME
        DATABASE_USERNAME                = var.postgres_credentials[env].DATABASE_USERNAME
        DATABASE_PASSWORD                = var.postgres_credentials[env].DATABASE_PASSWORD
        DATABASE_SSL                     = lookup(var.postgres_credentials[env], "DATABASE_SSL", "true")
        DATABASE_SSL_REJECT_UNAUTHORIZED = lookup(var.postgres_credentials[env], "DATABASE_SSL_REJECT_UNAUTHORIZED", "false")
      }
    },
    {
      for env in local.sorted_environments : "jwt-${env}" => {
        JWT_SECRET = lookup(lookup(var.jwt_secrets, env, {}), "JWT_SECRET", random_password.jwt[env].result)
      }
    },
    {
      for env in local.sorted_environments : "strapi-${env}" => {
        APP_KEYS = lookup(lookup(var.strapi_secrets, env, {}), "APP_KEYS", join(",", [
          for index in ["0", "1", "2", "3"] : random_password.app_keys["${env}-${index}"].result
        ]))
        API_TOKEN_SALT      = lookup(lookup(var.strapi_secrets, env, {}), "API_TOKEN_SALT", random_password.api_token_salt[env].result)
        ADMIN_JWT_SECRET    = lookup(lookup(var.strapi_secrets, env, {}), "ADMIN_JWT_SECRET", random_password.admin_jwt_secret[env].result)
        TRANSFER_TOKEN_SALT = lookup(lookup(var.strapi_secrets, env, {}), "TRANSFER_TOKEN_SALT", random_password.transfer_token_salt[env].result)
        ENCRYPTION_KEY      = lookup(lookup(var.strapi_secrets, env, {}), "ENCRYPTION_KEY", random_password.encryption_key[env].result)
        JWT_SECRET          = lookup(lookup(var.jwt_secrets, env, {}), "JWT_SECRET", random_password.jwt[env].result)
      }
    },
    {
      for env in local.sorted_environments : "s3-${env}" => {
        S3_ACCESS_KEY_ID     = var.s3_credentials[env].S3_ACCESS_KEY_ID
        S3_SECRET_ACCESS_KEY = var.s3_credentials[env].S3_SECRET_ACCESS_KEY
        S3_REGION            = var.s3_credentials[env].S3_REGION
        S3_BUCKET            = lookup(var.s3_credentials[env], "S3_BUCKET", "strapi-${env}")
        IIIF_BUCKET          = lookup(var.s3_credentials[env], "IIIF_BUCKET", "iiif-${env}")
        S3_ENDPOINT          = lookup(var.s3_credentials[env], "S3_ENDPOINT", "")
        S3_FORCE_PATH_STYLE  = lookup(var.s3_credentials[env], "S3_FORCE_PATH_STYLE", "false")
      }
    }
  )

  common_tags = merge(var.freeform_tags, {
    Project   = var.project_name
    Component = "vault"
  })
}

resource "random_password" "jwt" {
  for_each = var.environments

  length  = 48
  special = true
}

resource "random_password" "app_keys" {
  for_each = {
    for pair in setproduct(var.environments, toset(["0", "1", "2", "3"])) :
    "${pair[0]}-${pair[1]}" => {
      env = pair[0]
    }
  }

  length  = 32
  special = false
}

resource "random_password" "api_token_salt" {
  for_each = var.environments

  length  = 32
  special = true
}

resource "random_password" "admin_jwt_secret" {
  for_each = var.environments

  length  = 48
  special = true
}

resource "random_password" "transfer_token_salt" {
  for_each = var.environments

  length  = 32
  special = true
}

resource "random_password" "encryption_key" {
  for_each = var.environments

  length  = 32
  special = false
}

module "vault_secrets" {
  source = "../../modules/vault-secrets"

  compartment_id  = var.compartment_id
  name_prefix     = var.project_name
  secrets         = local.secret_definitions
  secret_payloads = local.secret_payloads

  iam_policy_compartment_id = coalesce(var.policy_compartment_id, var.compartment_id)
  iam_policy_name           = "${var.project_name}_external_secrets_vault_access"
  iam_policy_description    = "Allows External Secrets Operator to read AlMadar Vault secrets."
  iam_policy_statements     = var.external_secrets_iam_policy_statements

  freeform_tags = local.common_tags
}
