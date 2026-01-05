# GCP Deployment for Package Repository
# Deploys to GKE with optional GCS storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
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

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Get GKE cluster data
data "google_container_cluster" "cluster" {
  name     = var.gke_cluster_name
  location = var.gke_cluster_location
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  }
}

# Optional: GCS bucket for package storage
resource "google_storage_bucket" "packages" {
  count         = var.use_gcs_storage ? 1 : 0
  name          = var.gcs_bucket_name
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    app         = "package-repo"
    environment = var.environment
  }
}

# Service account for GCS access
resource "google_service_account" "package_repo" {
  count        = var.use_gcs_storage ? 1 : 0
  account_id   = "package-repo-${var.environment}"
  display_name = "Package Repository Service Account"
}

resource "google_storage_bucket_iam_member" "package_repo" {
  count  = var.use_gcs_storage ? 1 : 0
  bucket = google_storage_bucket.packages[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.package_repo[0].email}"
}

resource "google_service_account_key" "package_repo" {
  count              = var.use_gcs_storage ? 1 : 0
  service_account_id = google_service_account.package_repo[0].name
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
  ingress_class_name = "gce"
  ingress_annotations = {
    "kubernetes.io/ingress.class"                 = "gce"
    "kubernetes.io/ingress.global-static-ip-name" = var.static_ip_name
  }
  tls_enabled = var.tls_enabled

  storage_size  = var.storage_size
  storage_class = "standard-rwo"

  api_keys = var.api_keys

  # GCS uses S3-compatible API via interoperability
  s3_enabled    = var.use_gcs_storage
  s3_endpoint   = "https://storage.googleapis.com"
  s3_bucket     = var.use_gcs_storage ? google_storage_bucket.packages[0].name : ""
  s3_region     = var.gcp_region

  cpu_request    = var.cpu_request
  memory_request = var.memory_request
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
}
