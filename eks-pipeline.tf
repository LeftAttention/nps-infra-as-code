resource "aws_codebuild_project" "eks_deploy_pipeline_project" {
  name          = "${var.environament}-eks-deploy-pipeline-project"
  build_timeout = "5" # Timeout 5 minutes for this build
  service_role  = aws_iam_role.build-role.arn

  artifacts {
    type           = "CODEPIPELINE"
  }

  environment {
    privileged_mode = true
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = local.ecr_repo
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "EKS_IAM_ROLE"
      value = aws_iam_role.codebuild_eks_role.arn
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name  = "EKS_CLUSTER"
      value = module.eks.cluster_name
    }
    environment_variable {
      name  = "AWS_SECRET_ID"
      value = aws_secretsmanager_secret.backend_secret.id
    }
    environment_variable {
      name  = "OTHER_SECRET_ID"
      value = var.third_party_secrets_id
    }
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environament
    }
    environment_variable {
      name  = "CLOUDFLARE_ZONE_NAME"
      value = var.cloudflare_zone_name
    }
    environment_variable {
      name  = "ACM_CERTIFICATE_ARN"
      value = aws_acm_certificate.this.arn
    }
    environment_variable {
      name  = "ALB_NAME"
      value = var.backend_alb_name
    }
  }

source {
    buildspec           = data.local_file.buildspec_local_eks.content
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }

  tags = local.tags
}

data "local_file" "buildspec_local_eks" {
   filename = "${path.module}/pipeline/eks-buildspec.yaml"
}

resource "aws_codepipeline" "eks_deploy_pipeline_project" {
  name     = "${var.environament}-eks-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"
  execution_mode= "PARALLEL"

  variable  {
    name = "IMAGE_TAG"
    description = "Tag of the image to be deployed in eks cluster"
  }

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.bitbucket_connection.arn
        FullRepositoryId = var.helm_repo_name
        BranchName = var.helm_repo_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"



      configuration = {
        ProjectName = aws_codebuild_project.eks_deploy_pipeline_project.name
      EnvironmentVariables = jsonencode([
        {
          name  = "ECR_IMAGE_TAG"
          value = "#{variables.IMAGE_TAG}"
          type  = "PLAINTEXT"
        }
      ])
      }
    }
  }

  tags = local.tags
}

resource "aws_codestarnotifications_notification_rule" "eks_pipeline_notification" {
  detail_type    = "FULL"
  event_type_ids = local.pipeline_events

  name     = "${var.environament}-eks-pipeline-notification-rule"
  resource = aws_codepipeline.eks_deploy_pipeline_project.arn

  target {
    address = aws_sns_topic.discord_notifications.arn
  }
  depends_on = [ aws_sns_topic_policy.default ]

  tags = local.tags
}
