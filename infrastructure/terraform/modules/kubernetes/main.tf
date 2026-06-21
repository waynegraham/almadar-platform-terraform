locals {
  common_tags = merge(var.freeform_tags, {
    Region = var.region_key
  })
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name_prefix}-${var.region_key}-oke"
  vcn_id             = var.vcn_id
  type               = var.cluster_type
  freeform_tags      = local.common_tags

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = var.is_public_endpoint_enabled
    nsg_ids              = var.nsg_ids
    subnet_id            = var.endpoint_subnet_id
  }

  options {
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    service_lb_subnet_ids = var.service_lb_subnet_ids
  }
}

resource "oci_containerengine_node_pool" "this" {
  count = var.create_node_pool ? 1 : 0

  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name_prefix}-${var.region_key}-pool"
  node_shape         = var.node_shape
  ssh_public_key     = var.ssh_public_key
  freeform_tags      = local.common_tags

  node_config_details {
    size    = var.node_pool_size
    nsg_ids = var.nsg_ids

    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = var.worker_subnet_id
    }
  }

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gbs
  }

  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }
}
