# Módulo Monitoring: Log Analytics Workspace para observabilidad centralizada
# Configurado con política FinOps de retención mínima (30 días) y límite diario de ingesta

# checkov:skip=CKV_AZURE_115:Entorno de laboratorio dev/test permite consultas e ingesta pública sin necesidad de Private Link
# checkov:skip=CKV_AZURE_116:Cifrado con Customer Managed Key (CMK) no requerido en laboratorio para evitar costos adicionales de HSM

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags
}
