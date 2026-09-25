variable "name" {
  description = "Nombre unico global del Azure Container Registry (solo caracteres alfanumericos, 5-50 caracteres)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "El nombre del ACR debe ser alfanumerico y tener entre 5 y 50 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde se alojara el ACR"
  type        = string
}

variable "location" {
  description = "Region de Azure donde se desplegara el ACR"
  type        = string
}

variable "sku" {
  description = "Nivel de SKU del ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "El SKU del ACR debe ser Basic, Standard o Premium."
  }
}

variable "admin_enabled" {
  description = "Habilitar usuario administrador con contrasenas estaticas (deshabilitado por seguridad)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Etiquetas aplicables al ACR"
  type        = map(string)
  default     = {}
}
