# DevOps exercise: infrastructure foundation

Requirements: [PRUEBA.md](PRUEBA.md). The Node.js starter, container,
application pipeline and Kubernetes manifests are present; cloud deployment
remains environment-dependent and unverified.

## Cluster access

Requires AWS CLI v2, kubectl, the configured SSO profile, EKS access for its
role, and network access to the cluster API.

```bash
export AWS_PROFILE="050264659180_AdministratorAccess"
export AWS_REGION="us-east-1"
CLUSTER_NAME="dev-pichincha-dev-eks"

aws sso login --profile "$AWS_PROFILE"
aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

kubectl config current-context
kubectl get nodes
```

`update-kubeconfig` changes your local context. Confirm it before continuing.

## Argo CD

Requires Argo CD installed in `argocd`. Initial password on macOS:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -D
printf '\n'
```

Sign in as `admin` and change the initial password. If the secret was removed,
use the current password. Forward directly to the server deployment:

```bash
kubectl -n argocd port-forward deployment/argocd-server 8080:8080 --address 127.0.0.1
```

Open **https://localhost:8080**. The default certificate is self-signed.
Keep the terminal open; Ctrl+C stops forwarding. Only localhost is exposed.

## Application Kubernetes resources

The application resources use Kustomize:

```text
kubernetes/
├── application/
│   ├── base/
│   │   ├── ConfigMap, Deployment, Service, HPA
│   │   ├── Gateway, HTTPRoute
│   │   └── kustomization.yaml
│   └── overlays/
│       └── develop/
│           ├── kustomization.yaml
│           ├── SecretStore, ExternalSecret
│           └── environment-specific values
└── argocd/
    └── develop/
        └── application.yaml
```

The application starts with two replicas, exposes `/health` for liveness and
`/ready` for database readiness, and uses the `alb` GatewayClass managed by the
AWS Load Balancer Controller. Develop uses a single PostgreSQL StatefulSet
with an 8 GiB `gp3` PVC; this is a low-cost demonstration topology, not a
production database service. Terraform generates the database password using
the parameter convention
`/<project_name>/<environment>/application/database-password`, stores it as
an SSM Parameter Store `SecureString`, and the environment overlay references
that parameter through External Secrets Operator. The password is not
committed to Git.

The current Gateway exposes HTTP on port 80 because the application domain and
ACM certificate are not configured yet. The Gateway and HTTPRoute manifests
include commented HTTPS listener and HTTP-to-HTTPS redirect examples for the
future ACM/TLS configuration.

Create the develop Argo CD `Application` once after Argo CD is available:

```bash
kubectl apply -f kubernetes/argocd/develop/application.yaml
```

The resource is named `devsu-nodejs-develop`, targets the `develop` branch and
watches
`kubernetes/application/overlays/develop` on the `develop` branch. GitHub
Actions updates the image name and full commit SHA tag in that environment's
`kustomization.yaml`; Argo CD performs the synchronization.

## Architecture diagrams

### Runtime architecture

![AWS and Kubernetes runtime architecture](img/devops-architecture.png)

This diagram shows the request path from users through the ALB, Gateway API,
Node.js application, PostgreSQL StatefulSet and encrypted gp3 storage. It also
shows ECR, SSM Parameter Store, External Secrets and Argo CD.

### CI/CD and GitOps pipeline

![CI/CD and GitOps pipeline](img/devops-pipeline.png)

This diagram shows the pull request quality gates, merge-only image publication
to ECR, Kustomize image-tag update and Argo CD synchronization into EKS.

## Terraform

| Root                          | HCP workspace                        | Purpose             |
| ----------------------------- | ------------------------------------ | ------------------- |
| `terraform/infrastructure`    | `tf-infrastructure-pichincha-dev`    | VPC, EKS and ECR    |
| `terraform/cluster-bootstrap` | `tf-cluster-bootstrap-pichincha-dev` | Cluster controllers |

Apply infrastructure before bootstrap. Each root uses its own
`environments/develop.tfbackend`; never share or migrate state without review.
Configure inputs in HCP Terraform: `develop.tfvars` is not loaded by CI.
See [bootstrap setup](terraform/cluster-bootstrap/README.md).

## Pipelines

- [Infrastructure](.github/workflows/dev-infra.yml): infrastructure paths only.
- [Bootstrap](.github/workflows/dev-cluster-bootstrap.yml): bootstrap paths only.
- [Application](.github/workflows/dev-app.yml): Node.js quality checks,
  merge-only image publication and GitOps pull request.

Both target `develop`: PR runs format + plan; push runs format + apply.
Each also watches its own workflow file. Closed PRs do not trigger runs.
Set `TF_API_TOKEN` with plan/apply access in the GitHub environment. Optional
`TERRAFORM_VERSION` must match HCP. Fork PRs do not receive repository secrets.

The application pipeline runs `npm ci`, ESLint, unit tests and coverage on pull
requests and pushes. Only a push to `develop` after a merge builds the
multi-stage image and publishes an immutable full-commit-tagged image plus the
`latest` tag to ECR using GitHub OIDC. When
`kubernetes/application/overlays/develop/kustomization.yaml` exists,
the pipeline updates its image name and full commit SHA tag in an automation
branch and opens a GitOps pull request. After that pull request is merged,
Argo CD detects the Git change and performs the cluster deployment.

Configure these GitHub environment variables for the application workflow:

- `AWS_ROLE_ARN`: IAM role trusted by GitHub OIDC, with ECR push permissions.
- `AWS_REGION`: optional; defaults to `us-east-1`.
- `ECR_REPOSITORY`: optional; defaults to `dev-pichincha-dev-app`.
- `EKS_CLUSTER_NAME`: optional; defaults to `dev-pichincha-dev-eks`.

`AWS_ROLE_ARN` must be configured as a variable in each GitHub environment used
by the workflow. The job resolves the environment dynamically from the base
branch for pull requests or the pushed branch for merges. It is an ARN, not a
secret; each role trust policy must restrict the repository and its branch or
environment subject.

The application workflow does not add another AWS secret. `TF_API_TOKEN`
continues to be used only by the HCP Terraform workflows.

Direct pushes also apply; protect the branch and only allow trusted PRs.
Apply creates a fresh plan, not the speculative PR plan. Review it before
deployment. AWS resources incur costs; restrict EKS access and public node exposure.
Remove bootstrap resources before destroying infrastructure. SSO role access
applies to everyone who can assume the role, not just one session.
