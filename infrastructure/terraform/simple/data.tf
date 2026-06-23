data "oci_identity_compartments" "selected" {
  count = var.compartment_id == null && var.compartment_name != null ? 1 : 0

  compartment_id            = var.tenancy_ocid
  compartment_id_in_subtree = true
  name                      = var.compartment_name
  state                     = "ACTIVE"
}

data "oci_identity_availability_domains" "this" {
  compartment_id = local.compartment_id
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = local.compartment_id
}

data "oci_core_images" "app" {
  compartment_id           = local.compartment_id
  operating_system         = var.instance_image_operating_system
  operating_system_version = var.instance_image_operating_system_version
  shape                    = var.app_instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "runner" {
  compartment_id           = local.compartment_id
  operating_system         = var.instance_image_operating_system
  operating_system_version = var.instance_image_operating_system_version
  shape                    = var.runner_instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
