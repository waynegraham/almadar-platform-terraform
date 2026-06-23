resource "oci_core_network_security_group" "app" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-app-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "runner" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-runner-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "postgresql" {
  compartment_id = local.compartment_id
  display_name   = "${local.name_prefix}-postgresql-nsg"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "app_http" {
  for_each = toset(var.http_source_cidrs)

  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_https" {
  for_each = toset(var.http_source_cidrs)

  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_ssh" {
  for_each = toset(var.ssh_source_cidrs)

  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "runner_ssh" {
  for_each = toset(var.ssh_source_cidrs)

  network_security_group_id = oci_core_network_security_group.runner.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "postgres_from_app" {
  network_security_group_id = oci_core_network_security_group.postgresql.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.app.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_egress_all" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "runner_egress_all" {
  network_security_group_id = oci_core_network_security_group.runner.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "postgres_egress_all" {
  network_security_group_id = oci_core_network_security_group.postgresql.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

