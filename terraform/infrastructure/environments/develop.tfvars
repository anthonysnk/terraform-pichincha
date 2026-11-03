## THEREAL ENVIRONMENT CONFIGURATION IS IN TERRAFORMM CLOUD
## THIS FILE CONTAINS AN EXAMPLE CONFIGURATION FOR THE DEV ENVIRONMENT
## Account Setup
aws_region  = "us-east-1"
environment = "dev"

## Network
vpc_cidr           = "172.20.0.0/16"
public_subnets     = ["172.20.0.0/24", "172.20.1.0/24", "172.20.2.0/24"]
private_subnets    = ["172.20.10.0/24", "172.20.11.0/24", "172.20.12.0/24"]
enable_nat_gateway = true

## Worker placement
## EBS volumes are bound to one availability zone, so the nodes must stay in the
## zone that holds the persistent volume. Keep this aligned with the database volume.
node_group_availability_zone = "us-east-1b"
