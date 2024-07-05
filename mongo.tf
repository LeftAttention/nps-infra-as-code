resource "random_password" "mongodb_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  keepers = {
    create = var.create_mongodb_release
  }
}

resource "aws_secretsmanager_secret" "mongodb_secret" {
  name            = "${var.environament}-mongodb-secret-${random_string.bucket_prefix.result}"
  description     = "MongoDB credentials secret"
  recovery_window_in_days = 0
  count           = var.create_mongodb_release ? 1 : 0

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_secret[0].id
  secret_string = jsonencode({
    password = random_password.mongodb_password.result
  })
  count         = var.create_mongodb_release ? 1 : 0
}
