output "resource_group_name" {
  description = "Nombre del Resource Group del backend de tfstate"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Nombre del Storage Account para tfstate"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Nombre del contenedor de blobs para tfstate"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_dev" {
  description = "Snippet de configuracion para envs/dev/backend.tf"
  value       = <<EOT
terraform {
  backend "azurerm" {
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "dev.tfstate"
    use_azuread_auth     = true
  }
}
EOT
}

output "backend_config_prod" {
  description = "Snippet de configuracion para envs/prod/backend.tf"
  value       = <<EOT
terraform {
  backend "azurerm" {
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "prod.tfstate"
    use_azuread_auth     = true
  }
}
EOT
}

output "github_actions_client_id" {
  description = "Client ID de la aplicación de Microsoft Entra ID para GitHub Actions (AZURE_CLIENT_ID)"
  value       = azuread_application.github_actions.client_id
}

output "github_actions_service_principal_id" {
  description = "Object ID del Service Principal asociado a GitHub Actions"
  value       = azuread_service_principal.github_actions.object_id
}

output "github_actions_tenant_id" {
  description = "Tenant ID de Microsoft Entra ID (AZURE_TENANT_ID)"
  value       = data.azurerm_client_config.current.tenant_id
}

output "github_actions_subscription_id" {
  description = "ID de la suscripción de Azure (AZURE_SUBSCRIPTION_ID)"
  value       = data.azurerm_client_config.current.subscription_id
}
