output "namespace" {
  description = "OCI Object Storage namespace."
  value       = module.object_storage.namespace
}

output "bucket_names" {
  description = "Created bucket names keyed by logical bucket name."
  value       = module.object_storage.bucket_names
}

output "bucket_ids" {
  description = "Created bucket IDs keyed by logical bucket name."
  value       = module.object_storage.bucket_ids
}

output "lifecycle_policy_ids" {
  description = "Lifecycle policy IDs keyed by logical bucket name."
  value       = module.object_storage.lifecycle_policy_ids
}

output "iam_policy_id" {
  description = "IAM policy OCID for Object Storage access."
  value       = module.object_storage.iam_policy_id
}
