resource "aws_sns_topic" "discord_notifications" {
  name = "${var.environament}-discord_notifications"

  tags = local.tags
}

module "sns_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  function_name          = "${var.environament}-sns-to-discord-lambda"
  handler                = "function.lambda_handler"
  runtime                = "python3.12"
  timeout                = 300
  source_path = "${path.module}/lambda/function.py"
  environment_variables = {
    SECRET_NAME  = var.discord_url_secrets
    region_name = data.aws_region.current.name
  }
  attach_policy_json = true
  policy_json = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*"
            ],
            "Resource": ["*"]
        }
    ]
  }
  EOT
  tags = local.tags
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = module.sns_lambda_function.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.discord_notifications.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.discord_notifications.arn
  protocol  = "lambda"
  endpoint  = module.sns_lambda_function.lambda_function_arn
}

data "aws_iam_policy_document" "sns_policy" {
  statement {
    sid       = "CodeNotification_publish"
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.discord_notifications.arn]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.discord_notifications.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}