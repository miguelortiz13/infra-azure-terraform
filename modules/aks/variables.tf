variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde residirá el cluster AKS"
  type        = string
}

variable "location" {
  description = "Región de Azure donde se desplegará el cluster AKS"
  type        = string
}

variable "dns_prefix" {
  description = "Prefijo DNS para el FQDN del API Server de Kubernetes"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Tier de SKU para el plano de control de AKS (Free, Standard, Premium). Para lab se usa Free."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier debe ser 'Free', 'Standard' o 'Premium'."
  }
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes. Si es null, Azure utiliza la versión default de la región."
  type        = string
  default     = null
}

variable "vnet_subnet_id" {
  description = "ID de la subnet delegada para los nodos del cluster AKS"
  type        = string
}

variable "node_pool_name" {
  description = "Nombre del node pool por defecto (alfanumérico, máx 12 caracteres)"
  type        = string
  default     = "system"
}

variable "vm_size" {
  description = "Tamaño de VM para el node pool por defecto (ej. Standard_D2as_v6)"
  type        = string
  default     = "Standard_D2as_v6"
}


variable "os_disk_size_gb" {
  description = "Tamaño del disco de sistema operativo en GB para los nodos"
  type        = number
  default     = 30
}

variable "os_disk_type" {
  description = "Tipo de disco de sistema operativo (Managed o Ephemeral)"
  type        = string
  default     = "Managed"
}

variable "enable_auto_scaling" {
  description = "Habilitar cluster autoscaler en el default node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Cantidad mínima de nodos para el autoscaler"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Cantidad máxima de nodos para el autoscaler"
  type        = number
  default     = 3
}

variable "node_count" {
  description = "Cantidad inicial de nodos para el default node pool"
  type        = number
  default     = 1
}

variable "oidc_issuer_enabled" {
  description = "Habilitar emisor OIDC para soporte de Azure Workload Identity"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Habilitar Workload Identity en AKS para federación de identidades sin secretos"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Plugin de red para AKS (kubenet, azure, none)"
  type        = string
  default     = "azure"
}

variable "network_plugin_mode" {
  description = "Modo del plugin de red (overlay para Azure CNI Overlay)"
  type        = string
  default     = "overlay"
}

variable "network_policy" {
  description = "Mecanismo de aplicación de Network Policies (calico, azure, cilium)"
  type        = string
  default     = "cilium"
}

variable "network_data_plane" {
  description = "Plano de datos de red (cilium o azure)"
  type        = string
  default     = "cilium"
}

variable "pod_cidr" {
  description = "Rango CIDR para los pods cuando se usa Azure CNI Overlay (no debe solapar con VNets)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Rango CIDR para servicios de Kubernetes (no debe solapar con VNets ni Pod CIDR)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Dirección IP para el servicio de DNS interno de Kubernetes (dentro de service_cidr)"
  type        = string
  default     = "10.0.0.10"
}

variable "acr_id" {
  description = "ID del Azure Container Registry sobre el cual se asignará el rol AcrPull a la kubelet identity"
  type        = string
  default     = null
}

variable "tags" {
  description = "Etiquetas a aplicar a todos los recursos del módulo"
  type        = map(string)
  default     = {}
}
