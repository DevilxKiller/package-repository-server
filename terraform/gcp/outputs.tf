output "namespace" {
  description = "Kubernetes namespace"
  value       = module.package_repo.namespace
}

output "domain" {
  description = "Package repository domain"
  value       = module.package_repo.domain
}

output "gcs_bucket" {
  description = "GCS bucket name"
  value       = var.use_gcs_storage ? google_storage_bucket.packages[0].name : null
}

output "apt_config" {
  description = "APT repository configuration"
  value       = module.package_repo.apt_config
}

output "yum_config" {
  description = "YUM repository configuration"
  value       = module.package_repo.yum_config
}

output "pacman_config" {
  description = "Pacman repository configuration"
  value       = module.package_repo.pacman_config
}

output "apk_config" {
  description = "APK repository configuration"
  value       = module.package_repo.apk_config
}
