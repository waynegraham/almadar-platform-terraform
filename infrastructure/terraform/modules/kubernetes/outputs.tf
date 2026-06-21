output "cluster_id" {
  description = "OKE cluster OCID."
  value       = oci_containerengine_cluster.this.id
}

output "cluster_name" {
  description = "OKE cluster name."
  value       = oci_containerengine_cluster.this.name
}

output "node_pool_id" {
  description = "OKE node pool OCID, if created."
  value       = try(oci_containerengine_node_pool.this[0].id, null)
}
