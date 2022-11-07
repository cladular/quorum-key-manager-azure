provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azuread" {}

provider "azapi" {}

data "azurerm_client_config" "current" {}

locals {
  name    = "${var.deployment_name}-${var.location}"
  db_user = "${var.deployment_name}${var.location}admin"
  stores  = file("${path.root}/stores.yml.tpl")
  vaults = templatefile("${path.root}/vaults.yml.tpl", {
    vault_name    = module.key_vault.vault_name
    tenant_id     = data.azurerm_client_config.current.tenant_id
    client_id     = module.managed_identity.client_id
    client_secret = module.managed_identity.client_secret
  })
  nodes = templatefile("${path.root}/nodes.yml.tpl", {
    node_url = var.node_url
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
}

module "vnet" {
  source = "./modules/vnet"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  service_endpoints   = ["Microsoft.Sql", "Microsoft.KeyVault"]
}

module "managed_identity" {
  source = "./modules/managed-identity"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "random_password" "this" {
  length = 16
}

module "database" {
  source = "./modules/database"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  admin_login         = local.db_user
  admin_password      = random_password.this.result
  subnet_id           = module.vnet.subnet_id
}

module "key_vault" {
  source = "./modules/key-vault"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  azure_tenant_id     = data.azurerm_client_config.current.tenant_id
  azure_object_id     = data.azurerm_client_config.current.object_id
  principal_id        = module.managed_identity.principal_id
  subnet_id           = module.vnet.subnet_id
}

module "file_share" {
  source = "./modules/file-share"

  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  share_name          = "config"
  files = {
    "nodes.yml"  = local.nodes
    "vaults.yml" = local.vaults
    "stores.yml" = local.stores
  }
}

module "container_app" {
  source = "./modules/container-app"

  name                 = local.name
  location             = var.location
  resource_group_id    = azurerm_resource_group.this.id
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.vnet.subnet_id
  storage_account_name = module.file_share.storage_account_name
  storage_account_key  = module.file_share.storage_account_key
  share_name           = "config"
  db_host              = module.database.server_fqdn
  db_database          = module.database.database_name
  db_user              = local.db_user
  db_password          = random_password.this.result

  depends_on = [
    module.database,
    module.key_vault,
    module.file_share
  ]
}
