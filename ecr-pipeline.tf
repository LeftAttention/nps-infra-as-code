resource "aws_codebuild_project" "ecr_push_pipeline_project" {
  name          = "${var.environament}-ecr-push-pipeline-project"
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
      name  = "IMAGE_TAG_PREFIX"
      value = var.environament
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }

source {
    buildspec           = data.local_file.buildspec_local.content
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }

  tags = local.tags
}

data "local_file" "buildspec_local" {
    filename = "${path.module}/pipeline/ecr-buildspec.yaml"
}

resource "aws_codepipeline" "ecr_push_pipeline" {
  name     = "${var.environament}-ecr-push-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"
  execution_mode= "PARALLEL"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.backend_repo_branch_name]
        }
      }
    }
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
        FullRepositoryId = var.backend_app_code_repo_name
        BranchName = var.backend_repo_branch_name
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
        ProjectName = aws_codebuild_project.ecr_push_pipeline_project.name
      }
    }
  }

  tags = local.tags
}

resource "aws_codestarconnections_connection" "bitbucket_connection" {
  name = "${var.environament}-bitbucket-connection"
  provider_type = "Bitbucket"

  tags = local.tags
}

resource "aws_codestarnotifications_notification_rule" "ecr_pipeline_notification" {
  detail_type    = "FULL"
  event_type_ids = local.pipeline_events

  name     = "${var.environament}-ecr-pipeline-notification-rule"
  resource = aws_codepipeline.ecr_push_pipeline.arn

  target {
    address = aws_sns_topic.discord_notifications.arn
  }
  depends_on = [ aws_sns_topic_policy.default ]

  tags = local.tags
}
