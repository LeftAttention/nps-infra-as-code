#codebuild.tf

data "aws_iam_policy_document" "build_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "build-role" {
  name               = "${var.environament}-codebuild-role-${random_string.bucket_prefix.result}"
  assume_role_policy = data.aws_iam_policy_document.build_assume_role.json

  tags = local.tags
}

resource "aws_iam_policy" "build-ecr" {
  name = "ECRPOLICY"
  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeImages",
          "secretsmanager:*",
          "codestar-connections:*",
          "sts:AssumeRole"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
    ],
    "Version" : "2012-10-17"
  })

  tags = local.tags
}
resource "aws_iam_policy" "eks-access" {
  name = "EKS-access"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster"
            ],
            "Resource": "*"
        }
    ]
} )

tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks" {
  role = aws_iam_role.build-role.name
  policy_arn = aws_iam_policy.eks-access.arn
}
resource "aws_iam_role_policy_attachment" "attachmentsss" {
  role = aws_iam_role.build-role.name
  policy_arn = aws_iam_policy.build-ecr.arn
}

data "aws_iam_policy_document" "build-policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  role   = aws_iam_role.build-role.name
  policy = data.aws_iam_policy_document.build-policy.json
   
}


resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.environament}-pipeline-bucket-${random_string.bucket_prefix.result}"

  tags = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket_encryption" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
# Our pipeline role
resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.environament}-pipeline-role-${random_string.bucket_prefix.result}"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json

  tags = local.tags
}

# Our policies, allows S3 access for artifacts and codebuild access to start builds.
data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
  statement  {
        actions = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeImages",
          "codestar-connections:*",
          "sns:*"
        ]
        resources = ["*"]
        effect = "Allow"
      }
}
resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.environament}-codepipeline_policy-${random_string.bucket_prefix.result}"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_eks_role" {
  name               = "${var.environament}-CodeBuildEKSRole-${random_string.bucket_prefix.result}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "eks_describe_policy" {
  statement {
    effect    = "Allow"
    actions   = ["eks:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_describe_policy_attachment" {
  role       = aws_iam_role.codebuild_eks_role.name
  policy_arn = aws_iam_policy.eks_describe_policy.arn
}

resource "aws_iam_policy" "eks_describe_policy" {
  name        = "${var.environament}-eks-describe-policy-${random_string.bucket_prefix.result}"
  description = "Policy to describe resources in Amazon EKS"
  policy      = data.aws_iam_policy_document.eks_describe_policy.json

  tags = local.tags
}
