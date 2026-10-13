output "acr_login_server" {
  description = "Servidor de login del ACR."
  value       = azurerm_container_registry.acr.login_server
}

output "ci_client_id" {
  description = "AZURE_CLIENT_ID del repo online-boutique-ci."
  value       = azuread_application.ci.client_id
}
