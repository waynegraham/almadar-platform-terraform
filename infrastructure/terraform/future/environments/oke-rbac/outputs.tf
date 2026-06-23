output "namespaces" {
  description = "Created Kubernetes namespaces."
  value       = module.rbac.namespaces
}

output "deployer_service_accounts" {
  description = "Created deployer ServiceAccounts keyed by namespace."
  value       = module.rbac.deployer_service_accounts
}

output "role_bindings" {
  description = "Created RoleBindings keyed by namespace."
  value       = module.rbac.role_bindings
}
