variable "ec2_instance_type" {
  description = "The EC2 instance type for the EKS nodes"
  type        = string
}


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name}-cluster"
  cluster_version = "1.31"
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  self_managed_node_groups = {
    example = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = var.ec2_instance_type
      min_size = 2
      max_size = 2
      desired_size = 2
    }
  }

  tags = local.tags
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.0.6"
  namespace  = "kube-system"

  values = [
    <<EOF
controller:
  service:
    type: LoadBalancer
EOF
  ]

  depends_on = [module.eks]
}


resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "24.3.0"

  create_namespace = true

  values = [
    <<EOF
server:
  persistentVolume:
    enabled: false
  service:
    type: ClusterIP
alertmanager:
  persistence:
    enabled: false
  service:
    type: ClusterIP
EOF
  ]

  depends_on = [module.eks]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "6.58.5"

  create_namespace = false

  values = [
    <<EOF
adminUser: "admin"
adminPassword: "admin"
service:
  type: LoadBalancer
persistence:
  enabled: false
EOF
  ]
  depends_on = [module.eks, helm_release.prometheus]
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}