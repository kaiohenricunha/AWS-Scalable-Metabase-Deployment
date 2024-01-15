################################################################################
# VPC
################################################################################
module "lab_vpc" {
  source = "../../infra/vpc"

  name     = "lab-vpc"
  vpc_cidr = "10.0.0.0/16"

  tags = {
    Environment = "lab"
    GithubRepo  = "aws-scalable-metabase-deployment"
    GithubOrg   = "kaiohenricunha"
  }
}

################################################################################
# EKS on Fargate and Karpenter
################################################################################

module "eks_fargate_karpenter" {
  source = "../../infra/eks-fargate-karpenter"

  cluster_name             = "metabase-lab"
  cluster_version          = "1.28"
  vpc_id                   = module.lab_vpc.vpc_id
  subnet_ids               = module.lab_vpc.private_subnets
  control_plane_subnet_ids = module.lab_vpc.intra_subnets

  providers = {
    kubectl.gavinbunney = kubectl.gavinbunney
    aws.virginia        = aws.virginia
  }

  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    metabase = {
      selectors = [
        { namespace = "metabase" }
      ]
    }
  }
}

################################################################################
# RDS
################################################################################

module "lab_rds" {
  source = "../../infra/rds"

  db_name     = "metabase"
  db_username = "metabase"
  db_port     = "3306"

  db_password = var.db_password

  vpc_security_group_ids = [module.eks_fargate_karpenter.cluster_primary_security_group_id]
  subnet_ids             = module.lab_vpc.private_subnets
}
