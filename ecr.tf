resource "aws_ecr_repository" "ecr_repository" {
  name                 = local.ecr_repo
  image_tag_mutability = "MUTABLE"


  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "prod_temp_api_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only the last 50 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev-"],
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Expire any other image after 10 day",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}