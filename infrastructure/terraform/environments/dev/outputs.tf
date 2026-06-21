output "riyadh" {
  description = "Riyadh regional outputs."
  value = {
    region           = local.regions.riyadh.region
    vcn_id           = module.network_riyadh.vcn_id
    subnet_ids       = module.network_riyadh.subnet_ids
    bucket_names     = module.object_storage_riyadh.bucket_names
    object_namespace = module.object_storage_riyadh.namespace
    oke_cluster_id   = module.kubernetes_riyadh.cluster_id
    oke_node_pool_id = module.kubernetes_riyadh.node_pool_id
    postgresql_id    = module.postgresql_riyadh.db_system_id
  }
}

output "jeddah" {
  description = "Jeddah regional outputs."
  value = {
    region           = local.regions.jeddah.region
    vcn_id           = module.network_jeddah.vcn_id
    subnet_ids       = module.network_jeddah.subnet_ids
    bucket_names     = module.object_storage_jeddah.bucket_names
    object_namespace = module.object_storage_jeddah.namespace
    oke_cluster_id   = module.kubernetes_jeddah.cluster_id
    oke_node_pool_id = module.kubernetes_jeddah.node_pool_id
    postgresql_id    = module.postgresql_jeddah.db_system_id
  }
}
