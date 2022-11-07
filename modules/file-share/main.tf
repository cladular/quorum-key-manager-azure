resource "random_string" "this" {
  length  = 24
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  name                     = random_string.this.result
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {}
}

resource "azurerm_storage_share" "this" {
  name                 = var.share_name
  storage_account_name = azurerm_storage_account.this.name
  quota                = 1
}

resource "local_file" "this" {
  for_each = var.files

  content  = each.value
  filename = each.key
}

resource "azurerm_storage_share_file" "this" {
  for_each = local_file.this

  name             = each.key
  storage_share_id = azurerm_storage_share.this.id
  source           = each.key
}

resource "null_resource" "delete_local_file" {
  for_each = local_file.this

  triggers = {
    once = timestamp()
  }

  depends_on = [
    azurerm_storage_share_file.this,
  ]

  provisioner "local-exec" {
    # For Windows
    # command = "del ${each.key}"

    # For Linux
    command = "rm -rf ${each.key}"
  }
}
