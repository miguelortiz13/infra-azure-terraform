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

module "acr" {
  source              = "../../modules/acr"
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
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
  purge_protection_enabled      = false
  secrets_officer_principal_ids = [data.azurerm_client_config.current.object_id]
  tags                          = var.tags
}

# Secreto de prueba para validar autorizacion y acceso RBAC
resource "azurerm_key_vault_secret" "test" {
  name            = "db-password-sample"
  value           = "DevOpsSREPasswd2026!"
  key_vault_id    = module.keyvault.key_vault_id
  content_type    = "text/plain"
  expiration_date = "2027-12-31T23:59:59Z"

  depends_on = [module.keyvault]
}


module "monitoring" {
  source              = "../../modules/monitoring"
  workspace_name      = "log-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = var.tags
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = "aks-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "aks-${var.project_name}-${var.environment}"
  sku_tier            = "Free"
  vnet_subnet_id      = module.network.subnet_ids["snet-aks"]
  vm_size             = "Standard_D4as_v6"
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 3
  node_count          = 1
  os_disk_size_gb     = 64
  acr_id              = module.acr.acr_id

  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = var.tags

  depends_on = [module.network, module.monitoring]
}
