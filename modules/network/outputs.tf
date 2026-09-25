output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "Espacio de direcciones de la Virtual Network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  description = "Mapa de IDs de las subnets creadas (clave => id)"
  value       = { for k, s in azurerm_subnet.subnets : k => s.id }
}

output "nsg_ids" {
  description = "Mapa de IDs de los NSGs creados (clave => id)"
  value       = { for k, n in azurerm_network_security_group.nsg : k => n.id }
}
