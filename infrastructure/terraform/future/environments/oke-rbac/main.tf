module "rbac" {
  source = "../../modules/kubernetes-rbac"

  namespaces                    = var.namespaces
  deployer_service_account_name = var.deployer_service_account_name

  labels = {
    "almadar.io/platform" = "true"
  }
}
