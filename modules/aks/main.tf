# Módulo AKS: Cluster de Kubernetes administrado en Azure
# Cumple con estándares de seguridad, costo y preparación para Workload Identity (P3, P6, P7)

resource "azurerm_kubernetes_cluster" "aks" {
  # checkov:skip=CKV_AZURE_115:Dev cluster requiere API server público para acceso directo desde estación de trabajo sin VPN ni bastion
  # checkov:skip=CKV_AZURE_117:Lab de desarrollo utiliza cifrado en reposo por defecto de Azure; CMK con Disk Encryption Set genera costos innecesarios
  # checkov:skip=CKV_AZURE_141:Cuentas locales habilitadas para permitir obtención de kubeconfig directo en entorno de laboratorio
  # checkov:skip=CKV_AZURE_170:El laboratorio utiliza sku_tier Free para optimizar costos de acuerdo a la restricción presupuestaria de $20 USD/mes
  # checkov:skip=CKV_AZURE_172:Secrets Store CSI Driver se integrará en proyectos posteriores (P7)
  # checkov:skip=CKV_AZURE_226:Discos efímeros de SO no son requeridos para este clúster de laboratorio; se utiliza disco administrado estándar
  # checkov:skip=CKV_AZURE_227:Cifrado en host deshabilitado para evitar sobrecostos y requisitos de cuota adicionales en el laboratorio
  # checkov:skip=CKV_AZURE_232:Cluster de lab de un solo node pool ejecuta tanto system como app pods para minimizar costo de instancias
  # checkov:skip=CKV_AZURE_4:Diagnósticos y monitoreo centralizado de Azure Monitor se implementan en el módulo monitoring (P1-08 / P4)
  # checkov:skip=CKV_AZURE_6:Rango de IPs de API Server dinámico para trabajo remoto desde estación personal


  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : var.cluster_name
  sku_tier            = var.sku_tier

  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = "patch"
  azure_policy_enabled      = true
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = var.node_pool_name
    vm_size              = var.vm_size
    vnet_subnet_id       = var.vnet_subnet_id
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.min_count : null
    max_count            = var.enable_auto_scaling ? var.max_count : null
    node_count           = var.node_count
    os_disk_size_gb      = var.os_disk_size_gb
    os_disk_type         = var.os_disk_type
    max_pods             = 50
    type                 = "VirtualMachineScaleSets"

    tags = var.tags
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    network_data_plane  = var.network_data_plane
    pod_cidr            = var.network_plugin_mode == "overlay" ? var.pod_cidr : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  tags = var.tags
}

# Asignación de rol AcrPull para que el kubelet de AKS pueda descargar imágenes del ACR sin credenciales estáticas
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                            = var.acr_id != null ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
