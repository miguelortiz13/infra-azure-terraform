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

module "monitoring" {
  source              = "../../modules/monitoring"
  workspace_name      = "log-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  retention_in_days   = 60
  daily_quota_gb      = 2.0
  tags                = var.tags
}

module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = "aks-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  dns_prefix                 = "aks-${var.project_name}-${var.environment}"
  sku_tier                   = "Standard"
  vnet_subnet_id             = module.network.subnet_ids["snet-aks"]
  vm_size                    = "Standard_D2as_v6"
  enable_auto_scaling        = true
  min_count                  = 2
  max_count                  = 5
  node_count                 = 2
  os_disk_size_gb            = 64
  acr_id                     = module.acr.acr_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = var.tags

  depends_on = [module.network, module.monitoring]
}

# Identidad administrada y credencial federada para External Secrets Operator (P3-05)
resource "azurerm_user_assigned_identity" "eso" {
  name                = "uami-eso-${var.project_name}-${var.environment}-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "eso_kv_secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.eso.principal_id
}

resource "azurerm_federated_identity_credential" "eso" {
  name                = "fic-eso-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.eso.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}
