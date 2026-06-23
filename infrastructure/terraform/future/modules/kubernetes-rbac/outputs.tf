output "namespaces" {
  description = "Created Kubernetes namespaces."
  value       = sort(tolist(var.namespaces))
}

output "deployer_service_accounts" {
  description = "Deployer ServiceAccounts keyed by namespace."
  value = {
    for namespace, service_account in kubernetes_service_account_v1.deployer :
    namespace => "${service_account.metadata[0].namespace}/${service_account.metadata[0].name}"
  }
}

output "role_bindings" {
  description = "Namespace deployer RoleBindings keyed by namespace."
  value = {
    for namespace, role_binding in kubernetes_role_binding_v1.namespace_deployer :
    namespace => "${role_binding.metadata[0].namespace}/${role_binding.metadata[0].name}"
  }
}
