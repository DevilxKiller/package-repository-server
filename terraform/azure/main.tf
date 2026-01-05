# Azure Deployment for Package Repository
# Deploys to AKS with optional Azure Blob storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
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

provider "azurerm" {
  features {}
}

# Get AKS cluster data
data "azurerm_kubernetes_cluster" "cluster" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
  }
}

# Optional: Storage account for package storage
resource "azurerm_storage_account" "packages" {
  count                    = var.use_blob_storage ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    app         = "package-repo"
    environment = var.environment
  }
}

resource "azurerm_storage_container" "packages" {
  count                 = var.use_blob_storage ? 1 : 0
  name                  = "packages"
  storage_account_name  = azurerm_storage_account.packages[0].name
  container_access_type = "private"
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
  ingress_class_name = "azure/application-gateway"
  ingress_annotations = {
    "kubernetes.io/ingress.class" = "azure/application-gateway"
  }
  tls_enabled = var.tls_enabled

  storage_size  = var.storage_size
  storage_class = "managed-premium"

  api_keys = var.api_keys

  # Azure Blob uses S3-compatible API via endpoint
  s3_enabled    = var.use_blob_storage
  s3_endpoint   = var.use_blob_storage ? azurerm_storage_account.packages[0].primary_blob_endpoint : ""
  s3_bucket     = var.use_blob_storage ? "packages" : ""
  s3_access_key = var.use_blob_storage ? azurerm_storage_account.packages[0].name : ""
  s3_secret_key = var.use_blob_storage ? azurerm_storage_account.packages[0].primary_access_key : ""

  cpu_request    = var.cpu_request
  memory_request = var.memory_request
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
}
