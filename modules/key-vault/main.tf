resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.azure_tenant_id
  sku_name                      = "premium"
  public_network_access_enabled = true
  soft_delete_retention_days    = 7

  access_policy {
    key_permissions    = ["Create", "List", "Get", "Delete", "Purge"]
    secret_permissions = ["Set", "List", "Get", "Delete", "Purge"]
    object_id          = var.azure_object_id
    tenant_id          = var.azure_tenant_id
  }

  access_policy {
    key_permissions = [
      "Get", "Sign", "Create", "List", "Delete", "Encrypt", "Decrypt", "Verify", "Purge", "Recover", "Restore", "Import", "Update"
    ]
    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
    object_id = var.principal_id
    tenant_id = var.azure_tenant_id
  }

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.subnet_id]
  }
}
