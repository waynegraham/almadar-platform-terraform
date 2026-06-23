variable "namespaces" {
  description = "Kubernetes namespaces to create and manage."
  type        = set(string)
  default     = ["dev", "test", "prod"]
}

variable "deployer_service_account_name" {
  description = "ServiceAccount name created in each namespace for CI/CD deployments."
  type        = string
  default     = "deployer"
}

variable "labels" {
  description = "Labels applied to namespaces and RBAC resources."
  type        = map(string)
  default     = {}
}
