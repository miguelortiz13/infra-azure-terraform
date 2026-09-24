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

variable "container_name" {
  description = "Nombre del contenedor de blobs para almacenar los archivos tfstate"
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Etiquetas comunes para los recursos de bootstrap"
  type        = map(string)
  default = {
    project     = "devops-sre-lab"
    managed_by  = "terraform"
    component   = "bootstrap"
    environment = "shared"
  }
}
