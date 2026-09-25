output "resource_group_name" {
  description = "Nombre del Resource Group del entorno dev"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Ubicacion del Resource Group"
  value       = azurerm_resource_group.rg.location
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Mapa de IDs de las subnets creadas"
  value       = module.network.subnet_ids
}

output "nsg_ids" {
  description = "Mapa de IDs de los NSGs asociados"
  value       = module.network.nsg_ids
}

output "acr_id" {
  description = "ID del Azure Container Registry"
  value       = module.acr.acr_id
}

output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "URL del login server del ACR"
  value       = module.acr.acr_login_server
}

output "key_vault_id" {
  description = "ID del Azure Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_name" {
  description = "Nombre del Azure Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI del Azure Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "test_secret_name" {
  description = "Nombre del secreto de prueba creado en Key Vault"
  value       = azurerm_key_vault_secret.test.name
}
