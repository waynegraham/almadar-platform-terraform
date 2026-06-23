locals {
  common_labels = merge(var.labels, {
    "app.kubernetes.io/managed-by" = "terraform"
  })
}

resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces

  metadata {
    name = each.key
    labels = merge(local.common_labels, {
      "almadar.io/environment" = each.key
    })
  }
}

resource "kubernetes_service_account_v1" "deployer" {
  for_each = var.namespaces

  metadata {
    name      = var.deployer_service_account_name
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
    labels    = local.common_labels
  }
}

resource "kubernetes_role_v1" "namespace_deployer" {
  for_each = var.namespaces

  metadata {
    name      = "namespace-deployer"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
    labels    = local.common_labels
  }

  rule {
    api_groups = [""]
    resources = [
      "configmaps",
      "pods",
      "pods/log",
      "secrets",
      "services",
      "serviceaccounts",
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "namespace_deployer" {
  for_each = var.namespaces

  metadata {
    name      = "namespace-deployer"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
    labels    = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.namespace_deployer[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.deployer[each.key].metadata[0].name
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
}
