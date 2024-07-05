resource "random_string" "bucket_prefix" {
  length  = 6
  numeric = false
  upper   = false
  special = false
  lower   = true
}