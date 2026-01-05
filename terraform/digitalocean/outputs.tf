output "namespace" {
  description = "Kubernetes namespace"
  value       = module.package_repo.namespace
}

output "domain" {
  description = "Package repository domain"
  value       = module.package_repo.domain
}

output "spaces_bucket" {
  description = "Spaces bucket name"
  value       = var.use_spaces_storage ? digitalocean_spaces_bucket.packages[0].name : null
}

output "spaces_endpoint" {
  description = "Spaces endpoint"
  value       = var.use_spaces_storage ? "https://${var.do_region}.digitaloceanspaces.com" : null
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
