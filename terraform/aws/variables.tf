variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "package-repo"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "package-repo"
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "package-repo"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "domain" {
  description = "Domain name for package repository"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for TLS"
  type        = string
  default     = ""
}

variable "storage_size" {
  description = "Storage size"
  type        = string
  default     = "50Gi"
}

variable "use_s3_storage" {
  description = "Use S3 for package storage"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for packages"
  type        = string
  default     = "package-repo-packages"
}

variable "api_keys" {
  description = "API keys for authentication"
  type        = list(string)
  sensitive   = true
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "1Gi"
}
