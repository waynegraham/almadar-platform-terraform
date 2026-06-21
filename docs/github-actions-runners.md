# GitHub Actions OCI Runners

AlMadar uses GitHub Actions Runner Controller (ARC) on OKE to provide ephemeral,
autoscaled, OCI-hosted self-hosted runners for the GitHub organization.

## Architecture

- `arc-system`: namespace for the ARC controller.
- `arc-runners`: namespace for runner scale sets and short-lived runner pods.
- `almadar-oci-oke`: GitHub Actions runner label and ARC scale set name.
- `arc-github-app`: Kubernetes Secret created from OCI Vault by External
  Secrets Operator.

The runner scale set is organization-scoped with:

```yaml
githubConfigUrl: https://github.com/<GITHUB_ORG>
runnerScaleSetName: almadar-oci-oke
minRunners: 0
maxRunners: 10
```

Workflows target the OKE runners with:

```yaml
runs-on: almadar-oci-oke
```

## GitHub App

Create a GitHub App owned by the organization.

Required repository permissions:

- Actions: read
- Metadata: read

Required organization permissions:

- Self-hosted runners: write

Subscribe to events:

- Workflow job

Install the app on the organization and record:

- App ID
- Installation ID
- Private key PEM

## OCI Vault Secret

Store the GitHub App credentials in OCI Vault as a JSON secret named:

```text
almadar-github-actions-runner-controller
```

Payload shape:

```json
{
  "github_app_id": "<APP_ID>",
  "github_app_installation_id": "<INSTALLATION_ID>",
  "github_app_private_key": "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
}
```

External Secrets reads this payload and creates the Kubernetes Secret
`arc-github-app` in `arc-runners`. Do not commit the App ID, Installation ID, or
private key.

## Deploy

Prerequisites:

1. OKE cluster and `dev`, `test`, `prod` namespaces are already provisioned.
2. External Secrets Operator is installed and configured with
   `infrastructure/kubernetes/external-secrets`.
3. The OCI Vault secret above exists and the External Secrets workload identity
   can read it.
4. Helm can pull OCI charts from `ghcr.io`.

Apply the shared Kubernetes objects:

```bash
kubectl apply -k infrastructure/kubernetes/actions-runner-controller
kubectl -n arc-runners wait externalsecret/arc-github-app --for=condition=Ready --timeout=120s
```

Install the ARC controller:

```bash
helm upgrade --install arc \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
  --namespace arc-system \
  --values infrastructure/helm/actions-runner-controller/controller-values.yaml
```

Install the organization runner scale set:

```bash
helm upgrade --install almadar-oci-runners \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  --namespace arc-runners \
  --values infrastructure/helm/actions-runner-controller/runner-scale-set-values.yaml \
  --set githubConfigUrl=https://github.com/<GITHUB_ORG>
```

## Verify

Run the manual workflow:

```text
.github/workflows/oci-runner-smoke-test.yml
```

Expected result:

1. The job queues with `runs-on: almadar-oci-oke`.
2. ARC creates an ephemeral runner pod in `arc-runners`.
3. The job completes on the OCI-hosted runner.
4. The runner pod exits and is removed after the job finishes.

Useful checks:

```bash
kubectl -n arc-system get pods
kubectl -n arc-runners get pods
kubectl -n arc-runners get autoscalingrunnersets
kubectl -n arc-runners logs -l app.kubernetes.io/name=gha-runner-scale-set
```

## Operations

Use `maxRunners` in
`infrastructure/helm/actions-runner-controller/runner-scale-set-values.yaml` to
control burst capacity and OCI node-pool cost exposure.

Keep `minRunners: 0` unless queue latency becomes a measured problem. Idle
self-hosted runners consume OKE capacity even when no workflows are running.
