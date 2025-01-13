# Terraform variables
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (DEV, QA, Production)"
  type        = string
}

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name   = "particle41-${var.environment}"
  region = var.aws_region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Environment = var.environment
    Terraform  = "true"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "remote_state" {
  source = "ansraliant/s3-state/aws"

  bucket_name    = "${local.name}-${var.environment}-tfstate"
  dynamodb_table = "${local.name}-${var.environment}-tflock"
  states         = { infra = "../backend.tf.json" }
}