output "namespace" {
  description = "Kubernetes namespace"
  value       = module.package_repo.namespace
}

output "domain" {
  description = "Package repository domain"
  value       = module.package_repo.domain
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = var.use_s3_storage ? aws_s3_bucket.packages[0].id : null
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
