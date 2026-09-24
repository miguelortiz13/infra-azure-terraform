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
