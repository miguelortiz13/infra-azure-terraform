output "acr_id" {
  description = "ID del Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "URL del login server del ACR (ej. myacr.azurecr.io)"
  value       = azurerm_container_registry.acr.login_server
}

output "admin_enabled" {
  description = "Indica si el usuario admin esta habilitado"
  value       = azurerm_container_registry.acr.admin_enabled
}
