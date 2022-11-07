resource "azurerm_postgresql_server" "this" {
  name                         = "psql-${var.name}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku_name                     = "GP_Gen5_2"
  storage_mb                   = 5120
  backup_retention_days        = 7
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  version                      = "11"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "this" {
  name                = "psqldb-${var.name}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.this.name
  charset             = "UTF8"
  collation           = "en-US"
}

resource "azurerm_postgresql_virtual_network_rule" "this" {
  name                = "rule-snet-${var.name}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.this.name
  subnet_id           = var.subnet_id
}
