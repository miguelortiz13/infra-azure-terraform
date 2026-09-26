output "workspace_id" {
  description = "ID del recurso de Log Analytics Workspace en Azure"
  value       = azurerm_log_analytics_workspace.law.id
}

output "workspace_guid" {
  description = "GUID identificador del workspace (usado por agentes de monitoreo)"
  value       = azurerm_log_analytics_workspace.law.workspace_id
}

output "workspace_name" {
  description = "Nombre del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.name
}

output "primary_shared_key" {
  description = "Clave compartida primaria para autenticación de ingesta en el workspace"
  value       = azurerm_log_analytics_workspace.law.primary_shared_key
  sensitive   = true
}
