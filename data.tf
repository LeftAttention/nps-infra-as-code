data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

data "cloudflare_zone" "this" {
  name = var.cloudflare_zone_name
}

locals {
  ecr_repo  = "${var.environament}-backend-ecr-repo"

  name       =   "${var.environament}-backend"
  region     = coalesce(var.aws_region, data.aws_region.current.name)
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Company   = "twinciti"
    Terraform = "true"
    Environment = var.environament
    application = "backend"
  }
  pipeline_events = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded",
  ]
}

