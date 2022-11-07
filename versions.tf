terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.30.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.29.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "=1.0.0"
    }
  }
}
