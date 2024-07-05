resource "aws_iam_role" "grafana_role" {
  name = "${var.environament}-grafanaAccessRole-${random_string.bucket_prefix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = "${module.eks.eks_managed_node_groups["baseline-infra"].iam_role_arn}"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "grafana_policy" {
  description = "Policy to allow access for grafana"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "timestream:*",
          "cloudwatch:*",
          "tag:GetResources",
          "ec2:DescribeTags", 
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "logs:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "grafana_role_policy" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_policy.arn
}

data "aws_secretsmanager_secret" "discord_alerts_secret" {
  name = var.discord_url_secrets
}

data "aws_secretsmanager_secret_version" "discord_alerts_secret_version" {
  secret_id = data.aws_secretsmanager_secret.discord_alerts_secret.id
}


resource "random_password" "grafana_password" {
  length           = 12
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "grafana_password_secret" {
  name = "${var.environament}-grafana-password-${random_string.bucket_prefix.result}"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "grafana_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.grafana_password_secret.id
  secret_string = random_password.grafana_password.result
}

