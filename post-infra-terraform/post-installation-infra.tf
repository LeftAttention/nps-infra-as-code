################################ providers ###############################

provider "aws" {
  region = var.aws_region
  allowed_account_ids = [var.account_id]
  max_retries = 50
}

provider "cloudflare" {
  api_token = jsondecode(data.aws_secretsmanager_secret_version.cloudflare_api_key.secret_string)["CLOUDFLARE_KEY"]
}

terraform {
  backend "s3" {
    bucket         = "twinciti-terraform-state-bucket-backend-dev"
    key            = "post-infra/terraform.tfstate"
    region         = "us-east-1"
  }
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.20"
    }
  }
}

################################ variables #####################################

variable "aws_region" {
  type = string
  description = "aws region"
}

variable "account_id" {
  type = string
  description = "aws account id"
}

variable "alb_name" {
  type = string
  description = "Name of the alb"
}

variable "damain_name" {
  type = string
  description = "prefix of domain"
}

variable "cloudflare_zone_name" {
  type = string
  description = "Name of cloudflare zone"
}

variable "cloudflare_secret_name" {
  type = string
  description = "Name of cloudflare secret"
}

############################# data sources ####################################

data "aws_lb" "backend" {
  name = var.alb_name
}

data "cloudflare_zone" "this" {
  name = var.cloudflare_zone_name
}

data "aws_secretsmanager_secret" "cloudflare_api_key" {
  name = var.cloudflare_secret_name
}

data "aws_secretsmanager_secret_version" "cloudflare_api_key" {
  secret_id = data.aws_secretsmanager_secret.cloudflare_api_key.id
}

################################ resource ##############################

resource "cloudflare_record" "backend" {
  zone_id = data.cloudflare_zone.this.id
  name    = var.damain_name
  type    = "CNAME"
  value   = data.aws_lb.backend.dns_name
  ttl     = 60
  proxied = false

  allow_overwrite = true
}