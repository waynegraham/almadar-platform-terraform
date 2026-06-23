variable "compartment_id" {
  description = "OCID of the compartment where OKE resources are created."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for OKE resources."
  type        = string
}

variable "region_key" {
  description = "Short region key used in names and tags."
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID."
  type        = string
}

variable "endpoint_subnet_id" {
  description = "Subnet OCID for the Kubernetes API endpoint."
  type        = string
}

variable "service_lb_subnet_ids" {
  description = "Subnet OCIDs used for Kubernetes service load balancers."
  type        = list(string)
}

variable "worker_subnet_id" {
  description = "Subnet OCID for worker nodes."
  type        = string
}

variable "nsg_ids" {
  description = "NSG OCIDs applied to the cluster endpoint and node pool."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version."
  type        = string
}

variable "cluster_type" {
  description = "OKE cluster type."
  type        = string
  default     = "BASIC_CLUSTER"
}

variable "pods_cidr" {
  description = "Kubernetes pod CIDR."
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
  default     = "10.96.0.0/16"
}

variable "is_public_endpoint_enabled" {
  description = "Whether the OKE API endpoint receives a public IP."
  type        = bool
  default     = false
}

variable "create_node_pool" {
  description = "Create a managed node pool."
  type        = bool
  default     = false
}

variable "node_pool_size" {
  description = "Number of nodes in the managed node pool."
  type        = number
  default     = 2
}

variable "node_shape" {
  description = "Worker node shape."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  description = "OCPUs per worker node."
  type        = number
  default     = 2
}

variable "node_memory_gbs" {
  description = "Memory in GB per worker node."
  type        = number
  default     = 16
}

variable "node_image_id" {
  description = "OKE worker image OCID. Required when create_node_pool is true."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for worker nodes. Required when create_node_pool is true."
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Availability domain for the node pool placement."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default     = {}
}
