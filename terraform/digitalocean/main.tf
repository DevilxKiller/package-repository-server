# DigitalOcean Deployment for Package Repository
# Deploys to DOKS with optional Spaces storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
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

provider "digitalocean" {
  token = var.do_token
}

# Get DOKS cluster data
data "digitalocean_kubernetes_cluster" "cluster" {
  name = var.doks_cluster_name
}

provider "kubernetes" {
  host                   = data.digitalocean_kubernetes_cluster.cluster.endpoint
  token                  = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.digitalocean_kubernetes_cluster.cluster.endpoint
    token                  = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
  }
}

# Optional: Spaces bucket for package storage
resource "digitalocean_spaces_bucket" "packages" {
  count  = var.use_spaces_storage ? 1 : 0
  name   = var.spaces_bucket_name
  region = var.do_region

  acl = "private"
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
  ingress_class_name = "nginx"
  ingress_annotations = {
    "nginx.ingress.kubernetes.io/proxy-body-size" = "500m"
    "cert-manager.io/cluster-issuer"              = "letsencrypt-prod"
  }
  tls_enabled = var.tls_enabled

  storage_size  = var.storage_size
  storage_class = "do-block-storage"

  api_keys = var.api_keys

  # DigitalOcean Spaces is S3-compatible
  s3_enabled    = var.use_spaces_storage
  s3_endpoint   = var.use_spaces_storage ? "https://${var.do_region}.digitaloceanspaces.com" : ""
  s3_bucket     = var.use_spaces_storage ? digitalocean_spaces_bucket.packages[0].name : ""
  s3_region     = var.do_region
  s3_access_key = var.spaces_access_key
  s3_secret_key = var.spaces_secret_key

  cpu_request    = var.cpu_request
  memory_request = var.memory_request
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
}
