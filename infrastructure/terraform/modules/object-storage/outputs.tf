output "namespace" {
  description = "Object Storage namespace."
  value       = var.namespace
}

output "bucket_names" {
  description = "Bucket names keyed by logical name."
  value       = { for name, bucket in oci_objectstorage_bucket.this : name => bucket.name }
}

output "bucket_ids" {
  description = "Bucket IDs keyed by logical name."
  value       = { for name, bucket in oci_objectstorage_bucket.this : name => bucket.id }
}

output "lifecycle_policy_ids" {
  description = "Lifecycle policy IDs keyed by logical bucket name."
  value       = { for name, policy in oci_objectstorage_object_lifecycle_policy.this : name => policy.id }
}

output "iam_policy_id" {
  description = "Object Storage IAM policy OCID, if created."
  value       = try(oci_identity_policy.object_storage[0].id, null)
}
