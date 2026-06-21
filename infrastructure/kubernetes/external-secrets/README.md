# External Secrets for OCI Vault

These manifests configure External Secrets Operator to read JSON secret payloads
from OCI Vault and create the `almadar-secrets` Kubernetes Secret in the `dev`,
`test`, and `prod` namespaces.

The Strapi and Cantaloupe Helm charts already reference `almadar-secrets`, so no
secret values need to be stored in Helm values files or Kubernetes manifests.

## Prerequisites

1. Install External Secrets Operator in the `external-secrets` namespace.
2. Enable OCI Workload Identity for the External Secrets Operator service
   account.
3. Create the Vault secrets with Terraform from:

   ```text
   infrastructure/terraform/environments/vault
   ```

4. Grant the workload identity read access to the Vault secret bundles using the
   IAM policy statements in the Terraform environment.
5. Create the `dev`, `test`, and `prod` namespaces from the OKE RBAC Terraform
   stack before applying the ExternalSecret resources.

## Configure

Replace the placeholders in `cluster-secret-store.yaml` before applying:

```text
<OCI_VAULT_OCID>
<OCI_REGION>
```

Use Terraform outputs for the Vault OCID:

```bash
terraform -chdir=infrastructure/terraform/environments/vault output vault_id
```

## Apply

```bash
kubectl apply -k infrastructure/kubernetes/external-secrets
```

## Verify

```bash
kubectl -n dev get externalsecret almadar-secrets
kubectl -n dev get secret almadar-secrets
```

Repeat for `test` and `prod`.
