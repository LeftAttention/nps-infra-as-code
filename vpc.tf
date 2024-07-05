module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  map_public_ip_on_launch = true
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery" = "${local.name}-cluster"
  }

  enable_flow_log = var.enable_flow_logs
  flow_log_destination_type = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_retention_in_days = 30
  create_flow_log_cloudwatch_iam_role = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs

  tags = local.tags
}