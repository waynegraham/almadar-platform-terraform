## Local Development Setup

### MacOS

Requirements: 

* [Docker](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [k3d](https://k3d.io/stable/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)
* [https://helm.sh/](https://helm.sh/)
* [terraform](https://developer.hashicorp.com/terraform)

```bash
brew install k3d kubectl helm terraform
```

Create

```bash
k3d cluster create almadar
```

Verify

```bash
kubectl get nodes
```