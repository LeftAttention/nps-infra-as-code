variable "aws_region" {
  description = "Region where all the resources will be deployed"
  type        = string
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable flow logs for VPC"
}

variable "node_type" {
  type        = string
  description = "Type of nodes for initial EKS deployment"
}

variable "cloudflare_secret_name" {
  type        = string
  description = "Name of secret where Cloudflare API key is stored"
}

variable "cloudflare_zone_name" {
  type        = string
  description = "Name of the zone where to create the domain records"
}

variable "backend_domain_prefix" {
  type        = string
  description = "Prefix for backend"
}

variable "third_party_secrets_id" {
  type        = string
  description = "Name of the secret where all the third-party secrets are stored"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "backend_app_code_repo_name" {
  type        = string
  description = "Name of the Bitbucket repo for backend"
}

variable "backend_repo_branch_name" {
  type        = string
  description = "Name of the backend repo branch"
}

variable "helm_repo_name" {
  type        = string
  description = "Name of the Helm repo from Bitbucket"
}

variable "helm_repo_branch" {
  type        = string
  description = "Name of the Helm repo branch"
}

variable "environament" {
  type        = string
  description = "Name of the env like dev,prod and test"
}

variable "create_mongodb_release" {
  description = "Flag to create MongoDB Helm release"
  type        = bool
}

variable "discord_url_secrets" {
  description = "name of secret where discord URLS are stored"
}

variable "backend_alb_name" {
  type        = string
  description = "Name of the lab for backend application"
}