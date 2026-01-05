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

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_path" {
  description = "Path to the Helm chart (leave empty to use bundled chart)"
  type        = string
  default     = ""
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = null
}

variable "replica_count" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

# Image configuration
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

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

# Ingress configuration
variable "ingress_enabled" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default = {
    "nginx.ingress.kubernetes.io/proxy-body-size" = "500m"
  }
}

variable "domain" {
  description = "Domain name for the package repository"
  type        = string
}

variable "tls_enabled" {
  description = "Enable TLS"
  type        = bool
  default     = true
}

# Storage configuration
variable "storage_size" {
  description = "Storage size for packages"
  type        = string
  default     = "50Gi"
}

variable "storage_class" {
  description = "Storage class name"
  type        = string
  default     = ""
}

# Application configuration
variable "log_level" {
  description = "Log level (trace, debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "api_keys" {
  description = "API keys for authentication"
  type        = list(string)
  sensitive   = true
}

# S3 configuration
variable "s3_enabled" {
  description = "Enable S3 storage backend"
  type        = bool
  default     = false
}

variable "s3_endpoint" {
  description = "S3 endpoint URL"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 bucket name"
  type        = string
  default     = "packages"
}

variable "s3_region" {
  description = "S3 region"
  type        = string
  default     = "us-east-1"
}

variable "s3_access_key" {
  description = "S3 access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_secret_key" {
  description = "S3 secret key"
  type        = string
  default     = ""
  sensitive   = true
}

# Resource limits
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

# Scheduling
variable "node_selector" {
  description = "Node selector"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations"
  type        = list(any)
  default     = []
}

variable "affinity" {
  description = "Affinity rules"
  type        = any
  default     = {}
}
