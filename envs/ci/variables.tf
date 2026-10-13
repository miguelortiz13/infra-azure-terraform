variable "subscription_id" {
  description = "Suscripción del laboratorio (sub-lab)."
  type        = string
  default     = "43e1b4cf-e76c-4af6-b8cd-01f806c0ab09"
}

variable "location" {
  description = "Región de los recursos de CI."
  type        = string
  default     = "eastus2"
}

variable "github_repository" {
  description = "Repo que publica imágenes en el ACR (owner/repo)."
  type        = string
  default     = "miguelortiz13/online-boutique-ci"
}

variable "github_immutable_repository" {
  description = "Mismo repo con IDs inmutables (owner@owner_id/repo@repo_id), formato de sub claim inmutable de GitHub."
  type        = string
  default     = "miguelortiz13@89714460/online-boutique-ci@1391595352"
}

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "devops-sre-lab"
  }
}
