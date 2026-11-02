variable "aws_region" {
  description = "AWS region containing the EKS cluster."
  type        = string
}

variable "infrastructure_organization" {
  description = "HCP Terraform organization that owns the infrastructure workspace."
  type        = string
  default     = "personal-snk"
}

variable "infrastructure_workspace" {
  description = "HCP Terraform workspace containing the infrastructure state."
  type        = string
  default     = "tf-infrastructure-pichincha-dev"
}

variable "cluster_name_prefix" {
  description = "Prefix used for bootstrap IAM resource names."
  type        = string
  default     = "pichincha-dev"
}

variable "enable_ebs_csi" {
  description = "Install the Amazon EBS CSI driver."
  type        = bool
  default     = false
}

variable "enable_karpenter_controller" {
  description = "Install the Karpenter controller without enabling node provisioning."
  type        = bool
  default     = false
}

variable "enable_karpenter_provisioning" {
  description = "Create Karpenter provisioning resources such as NodePool and EC2NodeClass."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_karpenter_provisioning || var.enable_karpenter_controller
    error_message = "enable_karpenter_controller must be true when enable_karpenter_provisioning is true."
  }
}

variable "enable_cluster_autoscaler" {
  description = "Install Cluster Autoscaler."
  type        = bool
  default     = false
}

variable "enable_argocd_gateway" {
  description = "Expose the Argo CD UI through the ALB Gateway."
  type        = bool
  default     = false
}

variable "argocd_hostname" {
  description = "Hostname used by the optional Argo CD Gateway."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_argocd_gateway || trimspace(var.argocd_hostname) != ""
    error_message = "argocd_hostname must be set when enable_argocd_gateway is true."
  }
}

variable "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version."
  type        = string
  default     = "9.59.0"
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version."
  type        = string
  default     = "1.8.2"
}
