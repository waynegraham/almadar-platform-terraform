locals {
  app_user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker-engine docker-compose-plugin git
    systemctl enable --now docker
    mkdir -p /opt/almadar /var/lib/almadar
  EOT
  )

  runner_user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker-engine docker-compose-plugin git tar gzip
    systemctl enable --now docker
    mkdir -p /opt/github-runner
  EOT
  )
}

resource "oci_core_instance" "app" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = "${local.name_prefix}-app-vm"
  shape               = var.app_instance_shape
  freeform_tags       = local.common_tags

  shape_config {
    ocpus         = var.app_ocpus
    memory_in_gbs = var.app_memory_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    display_name     = "${local.name_prefix}-app-vnic"
    hostname_label   = "app"
    nsg_ids          = [oci_core_network_security_group.app.id]
    subnet_id        = oci_core_subnet.app.id
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.app.images[0].id
    boot_volume_size_in_gbs = var.app_boot_volume_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = local.app_user_data
  }
}

resource "oci_core_volume" "app_data" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = "${local.name_prefix}-app-data"
  size_in_gbs         = var.app_data_volume_gbs
  freeform_tags       = local.common_tags
}

resource "oci_core_volume_attachment" "app_data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.app.id
  volume_id       = oci_core_volume.app_data.id
  display_name    = "${local.name_prefix}-app-data-attachment"
}

resource "oci_core_instance" "runner" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = "${local.name_prefix}-github-runner-vm"
  shape               = var.runner_instance_shape
  freeform_tags       = local.common_tags

  shape_config {
    ocpus         = var.runner_ocpus
    memory_in_gbs = var.runner_memory_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    display_name     = "${local.name_prefix}-runner-vnic"
    hostname_label   = "runner"
    nsg_ids          = [oci_core_network_security_group.runner.id]
    subnet_id        = oci_core_subnet.runner.id
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.runner.images[0].id
    boot_volume_size_in_gbs = var.runner_boot_volume_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = local.runner_user_data
  }
}

