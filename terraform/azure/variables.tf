variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "aks_cluster_name" {
  description = "AKS cluster name"
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

variable "use_blob_storage" {
  description = "Use Azure Blob for package storage"
  type        = bool
  default     = false
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
  default     = "packagerepo"
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
