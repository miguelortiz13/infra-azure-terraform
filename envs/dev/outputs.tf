output "resource_group_name" {
  description = "Nombre del Resource Group del entorno dev"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Ubicacion del Resource Group"
  value       = azurerm_resource_group.rg.location
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Mapa de IDs de las subnets creadas"
  value       = module.network.subnet_ids
}

output "nsg_ids" {
  description = "Mapa de IDs de los NSGs asociados"
  value       = module.network.nsg_ids
}
