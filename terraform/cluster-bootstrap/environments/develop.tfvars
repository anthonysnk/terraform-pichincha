aws_region                  = "us-east-1"
infrastructure_organization = "personal-snk"
infrastructure_workspace    = "tf-infrastructure-pichincha-dev"
cluster_name_prefix         = "pichincha-dev"

# Optional capabilities remain disabled until their prerequisites are reviewed.
enable_ebs_csi                = true
enable_karpenter_controller   = false
enable_karpenter_provisioning = false
enable_cluster_autoscaler     = true
enable_argocd_gateway         = false
argocd_hostname               = ""

# These versions can be overridden here without changing the root module.
cluster_autoscaler_chart_version = "9.59.0"
karpenter_chart_version          = "1.8.2"
