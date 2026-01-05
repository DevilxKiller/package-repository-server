variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "gke_cluster_location" {
  description = "GKE cluster location (region or zone)"
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

variable "static_ip_name" {
  description = "Name of the static IP for ingress"
  type        = string
  default     = ""
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

variable "use_gcs_storage" {
  description = "Use GCS for package storage"
  type        = bool
  default     = false
}

variable "gcs_bucket_name" {
  description = "GCS bucket name for packages"
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
