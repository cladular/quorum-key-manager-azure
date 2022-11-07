resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-app-${var.name}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.1.0.0/16"]
  service_endpoints    = var.service_endpoints
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "rule-${var.name}-443"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
