# OCI Kubernetes Engine

Terraform root for the single AlMadar OKE cluster.

## Resources

- One OKE cluster.
- One managed node pool.
- Three worker nodes.
- `2` OCPU and `8GB` RAM per worker node.
- Generated kubeconfig written to `kubeconfig_path`.

## Network Inputs

Use values from the network stack `oke_cluster_network` output:

- `vcn_id`
- `endpoint_subnet_id`
- `worker_subnet_id`
- `service_lb_subnet_ids`
- `nsg_ids`

## Usage

```bash
cd infrastructure/terraform/environments/oke
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform output kubectl_command
```

Verify access:

```bash
kubectl --kubeconfig ./generated/oke-kubeconfig.yaml get nodes
```

Apply namespace and RBAC resources after the kubeconfig file has been generated:

```bash
cd ../oke-rbac
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```
