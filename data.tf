data "azuread_client_config" "current" {}


# Data source is used to access information about an existing key vault 
data "azurerm_key_vault" "main" {
  name                = "<provide your key vault name>"
  resource_group_name = "<provide resource group of the key vault"
}

