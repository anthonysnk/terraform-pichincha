# Cluster bootstrap

Installs Argo CD, AWS Load Balancer Controller, Metrics Server, Gateway API
CRDs and the `alb` GatewayClass on an existing EKS cluster.

## Setup

1. Apply infrastructure first. Its state must expose `eks_cluster_name`.
2. Use `personal-snk/tf-cluster-bootstrap-pichincha-dev`, selected by
  [develop.tfbackend](environments/develop.tfbackend). Keep its state separate.
3. Set `aws_region` in HCP. The infrastructure state defaults to
  `personal-snk/tf-infrastructure-pichincha-dev`; override via
  `infrastructure_organization` and `infrastructure_workspace` if needed.
4. Give the HCP execution identity infrastructure-state read access, AWS
  credentials, EKS permissions and network access to the Kubernetes API.
  The execution environment needs AWS CLI; a private API needs a VPC-connected agent.

CI does not load `develop.tfvars`. Do not migrate or replace existing state
without reviewing the target workspace.

## Pipeline

[dev-cluster-bootstrap.yml](../../.github/workflows/dev-cluster-bootstrap.yml)
uses the same pattern as infrastructure: `develop` PR -> format + plan;
push -> format + apply. Both filter bootstrap paths and the workflow file.
Set `TF_API_TOKEN` in the GitHub environment; optional `TERRAFORM_VERSION`
must match HCP. Protect direct pushes if apply must only follow merges.
The two workflows do not automatically wait for each other.

## Installation order

Pod Identity association -> Load Balancer Controller ready -> Argo CD.
Helm creates the `kube-system/aws-load-balancer-controller` ServiceAccount;
Pod Identity only associates its AWS role. Argo CD waits for the controller's
webhook so it can create Services. Review failed/pending releases before retrying;
the source fix does not repair an in-progress apply.

Optional components are disabled by default; see [variables.tf](variables.tf).
The External Secrets Operator is installed for the application’s SSM-backed
SecretStore. DNS is managed manually; ExternalDNS is not installed.

For EKS login, the Argo CD password and port-forward, use the
[root commands](../../README.md#cluster-access).
