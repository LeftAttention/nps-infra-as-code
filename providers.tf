provider "aws" {
  region = var.aws_region
  allowed_account_ids = [var.account_id]
  max_retries = 50
}

provider "aws" {
  alias  = "ecr"
  region = "us-east-1"
}

provider "cloudflare" {
  api_token = jsondecode(data.aws_secretsmanager_secret_version.cloudflare_api_key.secret_string)["CLOUDFLARE_KEY"]
}

terraform {
  backend "s3" {
    bucket         = "twinciti-terraform-state-bucket-backend-dev"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  alias = "karpenter"
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
  registry {
    url      = "oci://public.ecr.aws"
    username = data.aws_ecrpublic_authorization_token.token.user_name
    password = data.aws_ecrpublic_authorization_token.token.password
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}