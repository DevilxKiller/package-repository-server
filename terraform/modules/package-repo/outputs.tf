output "namespace" {
  description = "Kubernetes namespace"
  value       = var.create_namespace ? kubernetes_namespace.package_repo[0].metadata[0].name : var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.package_repo.name
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.package_repo.status
}

output "domain" {
  description = "Package repository domain"
  value       = var.domain
}

output "apt_config" {
  description = "APT repository configuration"
  value       = <<-EOT
    # Add to /etc/apt/sources.list.d/custom.list
    deb [signed-by=/usr/share/keyrings/repo.gpg] https://${var.domain}/deb stable main

    # Import GPG key
    curl -fsSL https://${var.domain}/repo.gpg | sudo gpg --dearmor -o /usr/share/keyrings/repo.gpg
  EOT
}

output "yum_config" {
  description = "YUM repository configuration"
  value       = <<-EOT
    # Add to /etc/yum.repos.d/custom.repo
    [custom-repo]
    name=Custom Repository
    baseurl=https://${var.domain}/rpm/$basearch/
    enabled=1
    gpgcheck=1
    gpgkey=https://${var.domain}/repo.gpg
  EOT
}

output "pacman_config" {
  description = "Pacman repository configuration"
  value       = <<-EOT
    # Add to /etc/pacman.conf
    [custom]
    SigLevel = Optional TrustAll
    Server = https://${var.domain}/arch/$arch
  EOT
}

output "apk_config" {
  description = "APK repository configuration"
  value       = <<-EOT
    # Add to /etc/apk/repositories
    https://${var.domain}/alpine/v3.19/main
  EOT
}
