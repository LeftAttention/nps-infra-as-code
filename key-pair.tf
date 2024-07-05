resource "aws_s3_bucket" "keys_bucket" {
  bucket = "${var.environament}-key-pair-bucket-${random_string.bucket_prefix.result}"

  tags = local.tags
}


resource "aws_s3_bucket_versioning" "keys_bucket_versioning" {
  bucket = aws_s3_bucket.keys_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "keys_bucket_encryption" {
  bucket = aws_s3_bucket.keys_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "tls_private_key" "tls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_s3_object" "tls_key_bucket_object" {
  key     = "${var.environament}-eks-nodes-key-pair"
  bucket  = aws_s3_bucket.keys_bucket.id
  content = tls_private_key.tls.private_key_pem

}
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.environament}-eks-nodes-key-pair"
  public_key = tls_private_key.tls.public_key_openssh

  tags = local.tags
}