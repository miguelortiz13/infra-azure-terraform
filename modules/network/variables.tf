variable "vnet_name" {
  description = "Nombre de la Virtual Network"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde se desplegara la red"
  type        = string
}

variable "location" {
  description = "Region de Azure donde se aprovisionara la red"
  type        = string
}

variable "address_space" {
  description = "Espacio de direcciones CIDR para la VNet"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrnetmask(cidr))])
    error_message = "Cada elemento en address_space debe ser un bloque CIDR valido (ej. 10.10.0.0/16)."
  }
}

variable "subnets" {
  description = "Mapa de subnets con sus prefijos y configuraciones"
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Disabled")
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : alltrue([
        for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))
      ])
    ])
    error_message = "Todos los address_prefixes de cada subnet deben ser bloques CIDR validos."
  }
}

variable "tags" {
  description = "Etiquetas aplicables a los recursos de red"
  type        = map(string)
  default     = {}
}
