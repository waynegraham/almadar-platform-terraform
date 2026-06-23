output "vcn_id" {
  description = "VCN OCID."
  value       = module.network.vcn_id
}

output "public_subnet_id" {
  description = "Public subnet OCID for load balancers."
  value       = module.network.public_subnet_ids["public"]
}

output "private_subnet_id" {
  description = "Private subnet OCID for OKE API endpoints and worker nodes."
  value       = module.network.private_subnet_ids["private"]
}

output "oke_cluster_network" {
  description = "Network values required by the OKE module."
  value = {
    vcn_id                = module.network.vcn_id
    endpoint_subnet_id    = module.network.private_subnet_ids["private"]
    worker_subnet_id      = module.network.private_subnet_ids["private"]
    service_lb_subnet_ids = [module.network.public_subnet_ids["public"]]
    nsg_ids               = [module.network.oke_nsg_id]
  }
}
