variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID used by Terraform."
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint for the OCI user."
  type        = string
}

variable "private_key_path" {
  description = "Path to the PEM private key for the OCI user."
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID where OKE resources are created."
  type        = string
}

variable "region" {
  description = "OCI region used by the provider."
  type        = string
  default     = "me-riyadh-1"
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "almadar"
}

variable "vcn_id" {
  description = "VCN OCID for the OKE cluster."
  type        = string
}

variable "endpoint_subnet_id" {
  description = "Private subnet OCID for the OKE Kubernetes API endpoint."
  type        = string
}

variable "worker_subnet_id" {
  description = "Private subnet OCID for OKE worker nodes."
  type        = string
}

variable "service_lb_subnet_ids" {
  description = "Public subnet OCIDs for Kubernetes Service load balancers."
  type        = list(string)
}

variable "nsg_ids" {
  description = "Network Security Group OCIDs applied to the OKE endpoint and worker nodes."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version."
  type        = string
  default     = "v1.33.1"
}

variable "cluster_type" {
  description = "OKE cluster type. Use BASIC_CLUSTER for the August 1 launch unless Enhanced features are required."
  type        = string
  default     = "BASIC_CLUSTER"
}

variable "node_image_id" {
  description = "OKE worker node image OCID for the selected region and Kubernetes version."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the node pool placement."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for worker nodes."
  type        = string
}

variable "is_public_endpoint_enabled" {
  description = "Whether the OKE API endpoint receives a public IP."
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Local path where Terraform writes the generated kubeconfig."
  type        = string
  default     = "./generated/oke-kubeconfig.yaml"
}

variable "freeform_tags" {
  description = "Additional freeform tags applied to OKE resources."
  type        = map(string)
  default     = {}
}
