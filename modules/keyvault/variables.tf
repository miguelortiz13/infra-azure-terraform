variable "name" {
  description = "Nombre unico global del Azure Key Vault (3-24 caracteres alfanumericos y guiones)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "El nombre del Key Vault debe tener entre 3 y 24 caracteres y contener solo letras, numeros y guiones."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde se alojara el Key Vault"
  type        = string
}

variable "location" {
  description = "Region de Azure donde se desplegara el Key Vault"
  type        = string
}

variable "sku_name" {
  description = "Nivel de SKU del Key Vault (standard o premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "El SKU del Key Vault debe ser standard o premium."
  }
}

variable "tenant_id" {
  description = "ID del Tenant de Azure AD / Entra ID"
  type        = string
}

variable "soft_delete_retention_days" {
  description = "Dias de retencion para eliminacion suave (soft delete)"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Habilitar proteccion contra purga (deshabilitado en laboratorios para facilitar destruccion)"
  type        = bool
  default     = false
}

variable "secrets_officer_principal_ids" {
  description = "Lista de Object IDs con rol Key Vault Secrets Officer para gestionar secretos"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Etiquetas aplicables al Key Vault"
  type        = map(string)
  default     = {}
}
