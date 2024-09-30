provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    cluster_name    = "${var.cluster_prefix}-cluster"
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_prefix}-cluster-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "eks_bottlerocket" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.cluster_prefix}-cluster"
  cluster_version = "1.30"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-mountpoint-s3-csi-driver = {}
  }
  iam_role_permissions_boundary = "arn:aws:iam::${local.account_id}:policy/eo_role_boundary"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    gpu = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["g6.xlarge"]

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1
      iam_role_permissions_boundary = "arn:aws:iam::${local.account_id}:policy/eo_role_boundary"


  }

  tags = local.tags
}
}
