output "principal_id" {
  value = azuread_service_principal.this.object_id
}

output "client_id" {
  value     = azuread_application.this.application_id
  sensitive = true
}

output "client_secret" {
  value     = azuread_service_principal_password.this.value
  sensitive = true
}
