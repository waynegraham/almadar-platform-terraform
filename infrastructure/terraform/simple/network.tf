data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_vcn" "this" {
  compartment_id = local.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${local.name_prefix}-vcn"
  dns_label      = replace(local.name_prefix, "-", "")
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-nat"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_service_gateway" "this" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-sgw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  services {
    service_id = data.oci_core_services.all.services[0].id
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-public-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-private-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_nat_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.this.id
    destination       = data.oci_core_services.all.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-public-sl"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-private-sl"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "app" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.app_subnet_cidr
  display_name               = "${local.name_prefix}-app-subnet"
  dns_label                  = "app"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "runner" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.runner_subnet_cidr
  display_name               = "${local.name_prefix}-runner-subnet"
  dns_label                  = "runner"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "database" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.database_subnet_cidr
  display_name               = "${local.name_prefix}-database-subnet"
  dns_label                  = "db"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  freeform_tags              = local.common_tags
}

