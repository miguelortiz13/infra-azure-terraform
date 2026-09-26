variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Region de Azure para los recursos"
  type        = string
  default     = "eastus2"
}

variable "project_name" {
  description = "Nombre del proyecto base para convencion de nombres"
  type        = string
  default     = "devops-sre"
}

variable "tags" {
  description = "Etiquetas comunes aplicables a todos los recursos de dev"
  type        = map(string)
  default = {
    project     = "devops-sre-lab"
    environment = "dev"
    managed_by  = "terraform"
    ci_pipeline = "github-actions"
  }
}
