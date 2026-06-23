output "vcn_id" {
  description = "VCN OCID."
  value       = oci_core_vcn.this.id
}

output "subnet_ids" {
  description = "Subnet OCIDs keyed by subnet name."
  value       = { for name, subnet in oci_core_subnet.this : name => subnet.id }
}

output "public_subnet_ids" {
  description = "Public subnet OCIDs keyed by subnet name."
  value       = { for name, subnet in oci_core_subnet.this : name => subnet.id if var.subnets[name].public }
}

output "private_subnet_ids" {
  description = "Private subnet OCIDs keyed by subnet name."
  value       = { for name, subnet in oci_core_subnet.this : name => subnet.id if !var.subnets[name].public }
}

output "oke_nsg_id" {
  description = "OKE network security group OCID."
  value       = oci_core_network_security_group.oke.id
}

output "postgresql_nsg_id" {
  description = "PostgreSQL network security group OCID."
  value       = oci_core_network_security_group.postgresql.id
}
