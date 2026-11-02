# ECR Module

Module to create an Amazon Elastic Container Registry (ECR) repository with lifecycle policies.

## Usage

```terraform
module "ecr" {
  source = "../modules/ecr"

  name                   = "my-app"
  image_tag_mutability   = "MUTABLE"
  scan_on_push          = true
  countNumber_to_expire = 10
  force_delete          = false
}
```

## Inputs

| Name                  | Description                        | Type     | Default     | Required |
| --------------------- | ---------------------------------- | -------- | ----------- | -------- |
| name                  | ECR repository name                | `string` | N/A         | Yes      |
| image_tag_mutability  | Tag mutability (MUTABLE/IMMUTABLE) | `string` | `"MUTABLE"` | No       |
| scan_on_push          | Scan images on push                | `bool`   | `false`     | No       |
| countNumber_to_expire | Number of images to keep           | `number` | `15`        | No       |
| life_cycle_policy     | Custom lifecycle policy            | `string` | `null`      | No       |
| force_delete          | Force repository deletion          | `bool`   | `false`     | No       |

## Outputs

| Name                | Description                  |
| ------------------- | ---------------------------- |
| data                | Complete ECR repository info |
| data.repository_url | Repository URL               |
| data.arn            | Repository ARN               |
| data.name           | Repository name              |
