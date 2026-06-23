# OCI Network Environments

Network-only Terraform roots for AlMadar platform environments.

## Environments

```text
environments/network/
  dev/
  test/
  prod/
```

Each environment creates:

- VCN
- Public subnet
- Private subnet
- Public and private security lists
- Public and private route tables
- NAT gateway
- Internet gateway
- OKE network security group

## OKE Integration

Use the `oke_cluster_network` output when deploying OKE:

```hcl
vcn_id                = output.oke_cluster_network.vcn_id
endpoint_subnet_id    = output.oke_cluster_network.endpoint_subnet_id
worker_subnet_id      = output.oke_cluster_network.worker_subnet_id
service_lb_subnet_ids = output.oke_cluster_network.service_lb_subnet_ids
nsg_ids               = output.oke_cluster_network.nsg_ids
```

The private subnet is routed through the NAT gateway for outbound access. The public subnet is routed through the internet gateway and is intended for Kubernetes service load balancers.

## Usage

```bash
cd infrastructure/terraform/environments/network/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Repeat for `test` and `prod`.
