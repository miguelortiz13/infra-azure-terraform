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
  address_space       = ["10.10.0.0/16"]

  subnets = {
    "snet-aks" = {
      address_prefixes = ["10.10.0.0/22"]
    }
    "snet-gateway" = {
      address_prefixes = ["10.10.4.0/24"]
    }
    "snet-endpoints" = {
      address_prefixes = ["10.10.5.0/24"]
    }
  }

  tags = var.tags
}
