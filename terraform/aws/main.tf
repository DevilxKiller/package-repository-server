# AWS Deployment for Package Repository
# Deploys to EKS with optional S3 storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get EKS cluster data
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Optional: S3 bucket for package storage
resource "aws_s3_bucket" "packages" {
  count  = var.use_s3_storage ? 1 : 0
  bucket = var.s3_bucket_name

  tags = {
    Name        = "package-repo"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "packages" {
  count  = var.use_s3_storage ? 1 : 0
  bucket = aws_s3_bucket.packages[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "packages" {
  count  = var.use_s3_storage ? 1 : 0
  bucket = aws_s3_bucket.packages[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM user for S3 access
resource "aws_iam_user" "package_repo" {
  count = var.use_s3_storage ? 1 : 0
  name  = "package-repo-${var.environment}"
}

resource "aws_iam_access_key" "package_repo" {
  count = var.use_s3_storage ? 1 : 0
  user  = aws_iam_user.package_repo[0].name
}

resource "aws_iam_user_policy" "package_repo" {
  count = var.use_s3_storage ? 1 : 0
  name  = "package-repo-s3-access"
  user  = aws_iam_user.package_repo[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.packages[0].arn,
          "${aws_s3_bucket.packages[0].arn}/*"
        ]
      }
    ]
  })
}

# Deploy package repository
module "package_repo" {
  source = "../modules/package-repo"

  release_name     = var.release_name
  namespace        = var.namespace
  create_namespace = true

  image_repository = var.image_repository
  image_tag        = var.image_tag

  domain          = var.domain
  ingress_enabled = true
  ingress_class_name = "alb"
  ingress_annotations = {
    "kubernetes.io/ingress.class"               = "alb"
    "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"     = "ip"
    "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
  }
  tls_enabled = true

  storage_size  = var.storage_size
  storage_class = "gp3"

  api_keys = var.api_keys

  s3_enabled    = var.use_s3_storage
  s3_bucket     = var.use_s3_storage ? aws_s3_bucket.packages[0].id : ""
  s3_region     = var.aws_region
  s3_access_key = var.use_s3_storage ? aws_iam_access_key.package_repo[0].id : ""
  s3_secret_key = var.use_s3_storage ? aws_iam_access_key.package_repo[0].secret : ""

  cpu_request    = var.cpu_request
  memory_request = var.memory_request
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
}
