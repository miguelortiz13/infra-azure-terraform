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

output "acr_id" {
  description = "ID del Azure Container Registry"
  value       = module.acr.acr_id
}

output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "URL del login server del ACR"
  value       = module.acr.acr_login_server
}

output "key_vault_id" {
  description = "ID del Azure Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_name" {
  description = "Nombre del Azure Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI del Azure Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "test_secret_name" {
  description = "Nombre del secreto de prueba creado en Key Vault"
  value       = azurerm_key_vault_secret.test.name
}

output "aks_cluster_id" {
  description = "ID del cluster AKS"
  value       = module.aks.cluster_id
}

output "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "URL del emisor OIDC de AKS para Workload Identity"
  value       = module.aks.oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID de la identidad administrada Kubelet de AKS"
  value       = module.aks.kubelet_identity_object_id
}

output "aks_kube_config_raw" {
  description = "Kubeconfig raw para conexión al cluster AKS (marcado sensitive para proteger credenciales)"
  value       = module.aks.kube_config_raw
  sensitive   = true
}
