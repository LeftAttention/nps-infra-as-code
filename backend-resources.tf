# Create S3 bucket
resource "aws_s3_bucket" "backend_bucket" {
  bucket = "${var.environament}-backend-data-bucket-${random_string.bucket_prefix.result}"

  tags = local.tags
}


resource "aws_s3_bucket_versioning" "backend_bucket_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  } 
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_bucket_encryption" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_user" "backend_user" {
  name = "${var.environament}-backend-bucket-user"

  tags = local.tags
}

resource "aws_iam_access_key" "backend_user_key" {
  user = aws_iam_user.backend_user.name
}

data "aws_iam_policy_document" "backend_user_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.backend_bucket.arn,
      "${aws_s3_bucket.backend_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "VisualEditor0"
    effect = "Allow"
    actions = [
      "aws-portal:ViewBilling",
      "ce:*",  # This allows all actions under Cost Explorer (ce)
      "aws-portal:ViewUsage"
    ]
    resources = ["*"]  # Specify the resources as needed
  }

  statement {
    sid    = "VisualEditor1"
    effect = "Deny"
    actions = [
      "aws-portal:ModifyBilling",
      "aws-portal:ViewPaymentMethods",
      "aws-portal:ModifyAccount",
      "aws-portal:UpdateConsoleActionSetEnforced",
      "aws-portal:ViewAccount",
      "aws-portal:ModifyPaymentMethods",
      "aws-portal:GetConsoleActionSetEnforced"
    ]
    resources = ["*"]  # Deny actions on all resources
  }
}


resource "aws_iam_user_policy" "backend_user_policy" {
  user   = aws_iam_user.backend_user.name
  policy = data.aws_iam_policy_document.backend_user_policy.json
}

# Store parameters in AWS Secrets Manager
resource "aws_secretsmanager_secret" "backend_secret" {
  name = "backend-aws-secrets-${random_string.bucket_prefix.result}"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "backend_secret_version" {
  secret_id     = aws_secretsmanager_secret.backend_secret.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY     = aws_iam_access_key.backend_user_key.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.backend_user_key.secret
    AWS_BUCKET           = aws_s3_bucket.backend_bucket.id
    AWS_REGION                = data.aws_region.current.name
  })
}
