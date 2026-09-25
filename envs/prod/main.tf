data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../modules/network"
  vnet_name           = "vnet-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.20.0.0/16"]

  subnets = {
    "snet-aks" = {
      address_prefixes = ["10.20.0.0/22"]
    }
    "snet-gateway" = {
      address_prefixes = ["10.20.4.0/24"]
    }
    "snet-endpoints" = {
      address_prefixes = ["10.20.5.0/24"]
    }
  }

  tags = var.tags
}

module "acr" {
  source              = "../../modules/acr"
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

module "keyvault" {
  source                        = "../../modules/keyvault"
  name                          = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku_name                      = "standard"
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled      = true
  secrets_officer_principal_ids = [data.azurerm_client_config.current.object_id]
  tags                          = var.tags
}
