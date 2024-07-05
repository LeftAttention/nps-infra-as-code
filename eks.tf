
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = "${local.name}-cluster"
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {

    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    baseline-infra = {
      instance_types = [var.node_type]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
      key_name       =  aws_key_pair.key_pair.key_name
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 3
        instance_metadata_tags      = "disabled"
      }
      iam_role_additional_policies = {
          AmazonEBSCSIDriverPolicy  = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${local.name}-cluster" = null
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = "${local.name}-cluster"
  })
}

module "eks_auth" {
  source = "aidanmelen/eks-auth/aws"
  eks    = module.eks

  map_roles = [
    {
      rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
      username =  "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers","system:nodes"]
    },
    {
      rolearn  = aws_iam_role.codebuild_eks_role.arn
      username =  "build"
      groups   = ["system:masters"]
    }
  ]
}
