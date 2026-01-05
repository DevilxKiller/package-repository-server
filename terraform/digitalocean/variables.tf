variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "doks_cluster_name" {
  description = "DOKS cluster name"
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

variable "tls_enabled" {
  description = "Enable TLS"
  type        = bool
  default     = true
}

variable "storage_size" {
  description = "Storage size"
  type        = string
  default     = "50Gi"
}

variable "use_spaces_storage" {
  description = "Use DigitalOcean Spaces for package storage"
  type        = bool
  default     = false
}

variable "spaces_bucket_name" {
  description = "Spaces bucket name"
  type        = string
  default     = "package-repo-packages"
}

variable "spaces_access_key" {
  description = "Spaces access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "Spaces secret key"
  type        = string
  default     = ""
  sensitive   = true
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
