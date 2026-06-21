locals {
  common_tags = merge(var.freeform_tags, {
    Region = var.region_key
  })

  public_subnets  = { for name, subnet in var.subnets : name => subnet if subnet.public }
  private_subnets = { for name, subnet in var.subnets : name => subnet if !subnet.public }
}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
  display_name   = "${var.name_prefix}-${var.region_key}-vcn"
  dns_label      = var.dns_label
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-igw"
  enabled        = true
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-nat"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_service_gateway" "this" {
  count = var.create_service_gateway ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-sgw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  services {
    service_id = data.oci_core_services.all[0].services[0].id
  }
}

data "oci_core_services" "all" {
  count = var.create_service_gateway ? 1 : 0

  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-public-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-private-rt"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_nat_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  dynamic "route_rules" {
    for_each = var.create_service_gateway ? [1] : []

    content {
      network_entity_id = oci_core_service_gateway.this[0].id
      destination       = data.oci_core_services.all[0].services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
    }
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-public-sl"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-private-sl"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr_blocks[0]
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "this" {
  for_each = var.subnets

  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = each.value.cidr_block
  display_name               = "${var.name_prefix}-${var.region_key}-${each.key}-subnet"
  dns_label                  = each.value.dns_label
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic
  route_table_id             = each.value.public ? oci_core_route_table.public.id : oci_core_route_table.private.id
  security_list_ids          = each.value.public ? [oci_core_security_list.public.id] : [oci_core_security_list.private.id]
  freeform_tags              = local.common_tags
}

resource "oci_core_network_security_group" "oke" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-oke-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "postgresql" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.region_key}-postgresql-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "postgresql_ingress" {
  network_security_group_id = oci_core_network_security_group.postgresql.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr_blocks[0]
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}
