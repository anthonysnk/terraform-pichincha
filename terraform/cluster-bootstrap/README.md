# Cluster bootstrap

This Terraform root manages the shared services installed on the existing EKS
cluster. It reads the cluster name from the infrastructure workspace state and
does not recreate infrastructure resources.

## State dependency

`data.tf` reads the HCP Terraform workspace
`tf-infrastructure-pichincha-dev` in the `personal-snk` organization through
the `terraform_remote_state` data source. The remote state must expose the
`eks_cluster_name` output before this root can initialize the AWS and Helm
providers.

The identity running this workspace needs read access to the infrastructure
workspace state. Do not copy the infrastructure state or its credentials into
this root.

## CI/CD

`.github/workflows/dev-cluster-bootstrap.yml` checks formatting and runs a
speculative plan for pull requests targeting `develop`. Pushes to `develop`
run apply after formatting succeeds. Both events filter changes to
`terraform/cluster-bootstrap/**` and the bootstrap workflow file. Direct pushes
also apply; require pull requests through branch protection if needed.

Configure these GitHub variables and secret for the `develop` environment:

| Setting             | Kind              | Purpose                                                 |
| ------------------- | ----------------- | ------------------------------------------------------- |
| `TF_API_TOKEN`      | Secret            | Token with plan/apply access to the bootstrap workspace |
| `TERRAFORM_VERSION` | Optional variable | Same Terraform version as the HCP workspace             |

The workflow follows the infrastructure template and initializes this root's
`remote` backend using `environments/<branch>.tfbackend`. The base branch is
used for pull requests and the ref name for pushes. `develop.tfbackend` selects
`personal-snk/tf-cluster-bootstrap-pichincha-dev`, separately from the
infrastructure state. It does not pass `develop.tfvars`; configure `aws_region`
and other inputs in the bootstrap HCP workspace. Changing the backend
declaration does not migrate state; review any existing state before deliberately
reinitializing a previously initialized local directory.

Use CLI-driven remote execution in the bootstrap workspace. Its execution
environment, not the GitHub runner, needs the AWS CLI on `PATH`, AWS credentials,
permission to describe EKS, an EKS access entry for its identity, and network
access to the Kubernetes API used by Helm and kubectl. Use a VPC-connected HCP
agent if that API is only privately reachable. Allow the bootstrap workspace
to read the infrastructure workspace state.

Apply infrastructure before bootstrap. These workflows do not automatically
order their runs when a change touches both roots. No workflow execution,
workspace configuration or cluster access has been verified against HCP/AWS.

## Inputs

- `aws_region`: AWS region containing the EKS cluster.
- `infrastructure_organization`: HCP Terraform organization for the state dependency.
- `infrastructure_workspace`: HCP Terraform workspace for the state dependency.

The development reference values are in
`environments/develop.tfvars`. This file contains no credentials. Terraform
Cloud workspace variables remain the source of truth for remote runs; use the
file only for local review or deliberate CLI runs.

## Controllers

The current baseline is:

- Argo CD chart `10.11.6`.
- Gateway API standard CRDs `v1.6.3`, applied from the official release
  manifest because Gateway API does not provide an official Helm chart for
  these CRDs.
- AWS Load Balancer Controller chart `3.6.2`, using Gateway API to provision
  internet-facing ALBs. Its AWS-specific Gateway API CRDs are also pinned to
  controller release `v3.6.2` and applied before the Helm release.
- An `alb` GatewayClass whose controller is `gateway.k8s.aws/alb`.
- Metrics Server chart `3.14.0` for HPA metrics.
- DNS records will be managed manually in Route 53 for now.

## Optional components

Optional capabilities are controlled by boolean Terraform variables, all with
`default = false`:

| Capability             | Flag                            | Current state                                                         |
| ---------------------- | ------------------------------- | --------------------------------------------------------------------- |
| AWS ACM certificate    | AWS/Route 53 configuration      | Use ACM for the ALB TLS certificate                                   |
| Amazon EBS CSI driver  | `enable_ebs_csi`                | Disabled; enable only if the application needs persistent EBS volumes |
| Karpenter controller   | `enable_karpenter_controller`   | Disabled                                                              |
| Karpenter provisioning | `enable_karpenter_provisioning` | Disabled                                                              |
| Cluster Autoscaler     | `enable_cluster_autoscaler`     | Disabled                                                              |
| Argo CD public Gateway | `enable_argocd_gateway`         | Disabled; use port-forward until required                             |

Karpenter is intentionally split into controller and provisioning flags. The
controller alone does not create nodes; provisioning also requires an
`EC2NodeClass`, a `NodePool`, IAM permissions, and interruption handling. The
current Spot managed node group remains the only node-capacity mechanism.

Each optional flag now controls its corresponding Helm, IAM, addon, CRD, or
Gateway resources. Terraform validates dependencies before activation; for
example, Karpenter provisioning cannot be enabled without its controller.

Optional resources are separated by responsibility:

- `ebs-csi.tf`
- `cluster-autoscaler.tf`
- `karpenter.tf`
- `argocd-gateway.tf`

The infrastructure node group carries the Cluster Autoscaler discovery tags
even while the controller is disabled, so enabling that flag later does not
require changing the node group shape.

ExternalDNS is intentionally not installed yet. Once a Gateway creates an
ALB/NLB hostname, create the Route 53 record manually from that hostname. The
domain must already be registered and delegated to the correct Route 53 public
hosted zone.

The infrastructure root installs the EKS Pod Identity Agent as an EKS addon.
This bootstrap root then creates the AWS Load Balancer Controller IAM role and
Pod Identity association, and installs the controller with Helm. Its
version-pinned IAM policy is downloaded from the official release. The standard
Gateway API CRDs are installed separately before the controller.
