output "app_url" {
  value = "https://${module.container_app.app_fqdn}"
}
