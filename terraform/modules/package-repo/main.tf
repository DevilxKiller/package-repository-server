# Package Repository Terraform Module
# This module deploys the package repository using Helm

terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

resource "kubernetes_namespace" "package_repo" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "package-repo"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "package_repo" {
  name       = var.release_name
  namespace  = var.create_namespace ? kubernetes_namespace.package_repo[0].metadata[0].name : var.namespace
  chart      = var.chart_path != "" ? var.chart_path : "${path.module}/../../../helm/package-repo"
  version    = var.chart_version

  values = [
    yamlencode({
      replicaCount = var.replica_count

      image = {
        repository = var.image_repository
        tag        = var.image_tag
        pullPolicy = var.image_pull_policy
      }

      ingress = {
        enabled   = var.ingress_enabled
        className = var.ingress_class_name
        annotations = var.ingress_annotations
        hosts = [
          {
            host = var.domain
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = var.tls_enabled ? [
          {
            secretName = "${var.release_name}-tls"
            hosts      = [var.domain]
          }
        ] : []
      }

      persistence = {
        data = {
          enabled      = true
          size         = var.storage_size
          storageClass = var.storage_class
        }
        gpg = {
          enabled      = true
          size         = "1Gi"
          storageClass = var.storage_class
        }
      }

      config = {
        logLevel = var.log_level
        apiKeys  = var.api_keys
        s3 = {
          enabled   = var.s3_enabled
          endpoint  = var.s3_endpoint
          bucket    = var.s3_bucket
          region    = var.s3_region
          accessKey = var.s3_access_key
          secretKey = var.s3_secret_key
        }
      }

      resources = {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      affinity     = var.affinity
    })
  ]

  depends_on = [kubernetes_namespace.package_repo]
}
