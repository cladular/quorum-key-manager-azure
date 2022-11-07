output "server_fqdn" {
  value = azurerm_postgresql_server.this.fqdn
}

output "database_name" {
  value = azurerm_postgresql_database.this.name
}
