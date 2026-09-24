variable "location" {
  description = "Region de Azure para el almacenamiento del estado"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group para el backend de Terraform"
  type        = string
  default     = "rg-devops-sre-tfstate"
}
