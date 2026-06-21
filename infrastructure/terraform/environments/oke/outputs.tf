output "cluster_id" {
  description = "OKE cluster OCID."
  value       = module.oke.cluster_id
}

output "cluster_name" {
  description = "OKE cluster name."
  value       = module.oke.cluster_name
}

output "node_pool_id" {
  description = "OKE node pool OCID."
  value       = module.oke.node_pool_id
}

output "kubeconfig_path" {
  description = "Local kubeconfig path written by Terraform."
  value       = local_sensitive_file.kubeconfig.filename
}

output "kubectl_command" {
  description = "Command for accessing the cluster with kubectl."
  value       = "kubectl --kubeconfig ${local_sensitive_file.kubeconfig.filename} get nodes"
}

output "cluster_kubeconfig" {
  description = "Generated kubeconfig content."
  value       = data.oci_containerengine_cluster_kube_config.this.content
  sensitive   = true
}
