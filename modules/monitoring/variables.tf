variable "workspace_name" {
  description = "Nombre del Log Analytics Workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde residirá el Log Analytics Workspace"
  type        = string
}

variable "location" {
  description = "Región de Azure donde se desplegará el recurso"
  type        = string
}

variable "sku" {
  description = "SKU del Log Analytics Workspace (PerGB2018 recomendado)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Días de retención de logs (mínimo 30 días para SKU PerGB2018 para optimizar costos FinOps)"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days debe ser de al menos 30 días y como máximo 730 días."
  }
}

variable "daily_quota_gb" {
  description = "Límite diario de ingesta en GB para evitar costos imprevistos en el laboratorio (FinOps). -1 para ilimitado."
  type        = number
  default     = 0.5
}

variable "tags" {
  description = "Etiquetas a aplicar a todos los recursos del módulo"
  type        = map(string)
  default     = {}
}
