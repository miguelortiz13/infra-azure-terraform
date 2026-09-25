output "cluster_id" {
  description = "ID del cluster de AKS en Azure"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "Nombre del cluster de AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "oidc_issuer_url" {
  description = "URL del emisor OIDC del cluster, requerida para Workload Identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID de la identidad administrada de Kubelet"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Client ID de la identidad administrada de Kubelet"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID de la identidad administrada del cluster (SystemAssigned)"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "kube_config_raw" {
  description = "Archivo kubeconfig para conectarse al cluster AKS vía kubectl. Marcado sensitive para evitar exposición de credenciales y tokens en logs."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Endpoint del Kubernetes API Server"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Certificado de cliente para autenticación con el API Server"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Clave privada de cliente para autenticación con el API Server"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado de la Autoridad Certificadora (CA) del cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}
