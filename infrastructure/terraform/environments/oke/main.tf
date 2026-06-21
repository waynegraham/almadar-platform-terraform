locals {
  name_prefix = "${var.project_name}-platform"
  region_key  = replace(var.region, "-", "")

  common_tags = merge(var.freeform_tags, {
    Project   = var.project_name
    Component = "oke"
    ManagedBy = "terraform"
  })
}

module "oke" {
  source = "../../modules/kubernetes"

  compartment_id             = var.compartment_id
  name_prefix                = local.name_prefix
  region_key                 = local.region_key
  vcn_id                     = var.vcn_id
  endpoint_subnet_id         = var.endpoint_subnet_id
  service_lb_subnet_ids      = var.service_lb_subnet_ids
  worker_subnet_id           = var.worker_subnet_id
  nsg_ids                    = var.nsg_ids
  kubernetes_version         = var.kubernetes_version
  is_public_endpoint_enabled = var.is_public_endpoint_enabled

  create_node_pool    = true
  node_pool_size      = 3
  node_shape          = "VM.Standard.E4.Flex"
  node_ocpus          = 2
  node_memory_gbs     = 8
  node_image_id       = var.node_image_id
  availability_domain = var.availability_domain
  ssh_public_key      = var.ssh_public_key

  freeform_tags = local.common_tags
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = module.oke.cluster_id
}

resource "local_sensitive_file" "kubeconfig" {
  content         = data.oci_containerengine_cluster_kube_config.this.content
  filename        = var.kubeconfig_path
  file_permission = "0600"
}
