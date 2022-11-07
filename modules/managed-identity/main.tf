resource "azuread_application" "this" {
  display_name = var.name
}

resource "azuread_service_principal" "this" {
  application_id = azuread_application.this.application_id
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.id
}
