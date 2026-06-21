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
