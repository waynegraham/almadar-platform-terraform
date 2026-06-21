# OKE Namespaces and RBAC

Terraform root for Kubernetes namespaces and namespace-scoped RBAC.

## Resources

For each namespace in `namespaces`, this stack creates:

- Namespace
- `deployer` ServiceAccount
- `namespace-deployer` Role
- `namespace-deployer` RoleBinding

Default namespaces:

- `dev`
- `test`
- `prod`

## Usage

Apply the OKE stack first so the kubeconfig exists:

```bash
cd infrastructure/terraform/environments/oke
terraform apply
```

Then apply RBAC:

```bash
cd ../oke-rbac
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Verify:

```bash
kubectl --kubeconfig ../oke/generated/oke-kubeconfig.yaml get namespaces dev test prod
```
