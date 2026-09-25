# Módulo AKS (`modules/aks`)

Este módulo aprovisiona un clúster de **Azure Kubernetes Service (AKS)** optimizado para entornos de laboratorio y preparado para arquitecturas cloud-native empresariales (GitOps, OIDC, Workload Identity y políticas de red avanzadas).

---

## 🎯 Capacidades Principales

1. **Azure CNI Overlay con Cilium**:
   - `network_plugin = "azure"` y `network_plugin_mode = "overlay"`: Los pods obtienen IPs de un espacio privado de pods (`pod_cidr = "10.244.0.0/16"`), evitando el agotamiento de direcciones IP privadas en la VNet de Azure.
   - `network_data_plane = "cilium"` y `network_policy = "cilium"`: Plano de datos de alto rendimiento eBPF con soporte nativo para `NetworkPolicy` estándar y `CiliumNetworkPolicy` (indispensable para P6).

2. **Workload Identity & OIDC**:
   - `oidc_issuer_enabled = true` y `workload_identity_enabled = true`: Habilita la federación de identidades OIDC entre ServiceAccounts de Kubernetes y Managed Identities de Azure Entra ID, eliminando la necesidad de contraseñas, secretos estáticos o service principals (necesario en P3, P6 y P7).

3. **Integración con ACR sin Secretos Estáticos**:
   - Asigna automáticamente el rol de Azure RBAC `AcrPull` a la Managed Identity del Kubelet (`kubelet_identity[0].object_id`) sobre el recurso de Azure Container Registry proporcionado en `var.acr_id`.
   - Ningún nodo ni pod necesita credenciales de administrador ni tokens estáticos (`imagePullSecrets`).

4. **Optimización Extrema de Costos (FinOps)**:
   - `sku_tier = "Free"`: SLA gratuito para plano de control en entornos de desarrollo.
   - Default Node Pool con `vm_size = "Standard_D2as_v6"` (2 vCPUs AMD EPYC, 8 GiB RAM de alto rendimiento) y autoescalado configurado (mínimo 1 nodo, máximo 3).
   - `os_disk_size_gb = 30`: Reduce el costo de almacenamiento de disco de 128 GB (por defecto en AKS) a 30 GB.


---

## 📋 Variables de Entrada (Inputs)

| Nombre | Tipo | Default | Descripción |
| :--- | :--- | :--- | :--- |
| `cluster_name` | `string` | N/A *(requerido)* | Nombre del cluster AKS |
| `resource_group_name` | `string` | N/A *(requerido)* | Nombre del Resource Group donde residirá el cluster |
| `location` | `string` | N/A *(requerido)* | Región de Azure |
| `dns_prefix` | `string` | `null` | Prefijo DNS para el FQDN del API Server (usa `cluster_name` si es null) |
| `sku_tier` | `string` | `"Free"` | Tier de SKU (`Free`, `Standard`, `Premium`) |
| `kubernetes_version` | `string` | `null` | Versión de Kubernetes (usa default regional si es null) |
| `vnet_subnet_id` | `string` | N/A *(requerido)* | ID de la subnet delegada para los nodos |
| `node_pool_name` | `string` | `"system"` | Nombre del node pool por defecto |
| `vm_size` | `string` | `"Standard_D2as_v6"` | Tamaño de máquina virtual para los nodos |
| `os_disk_size_gb` | `number` | `30` | Tamaño en GB del disco de SO |

| `os_disk_type` | `string` | `"Managed"` | Tipo de disco (`Managed` o `Ephemeral`) |
| `enable_auto_scaling` | `bool` | `true` | Habilitar cluster autoscaler |
| `min_count` | `number` | `1` | Mínimo de nodos para autoescalado |
| `max_count` | `number` | `3` | Máximo de nodos para autoescalado |
| `node_count` | `number` | `1` | Conteo inicial de nodos |
| `oidc_issuer_enabled` | `bool` | `true` | Habilitar emisor OIDC |
| `workload_identity_enabled` | `bool` | `true` | Habilitar Workload Identity |
| `network_plugin` | `string` | `"azure"` | Plugin de red (`azure`, `kubenet`) |
| `network_plugin_mode` | `string` | `"overlay"` | Modo del plugin de red (`overlay`) |
| `network_policy` | `string` | `"cilium"` | Motor de Network Policies (`cilium`, `azure`, `calico`) |
| `network_data_plane` | `string` | `"cilium"` | Plano de datos de red (`cilium`, `azure`) |
| `pod_cidr` | `string` | `"10.244.0.0/16"` | Rango CIDR para pods en modo overlay |
| `service_cidr` | `string` | `"10.0.0.0/16"` | Rango CIDR para servicios ClusterIP |
| `dns_service_ip` | `string` | `"10.0.0.10"` | IP del servicio CoreDNS |
| `acr_id` | `string` | `null` | ID del Azure Container Registry para asociar `AcrPull` |
| `tags` | `map(string)` | `{}` | Etiquetas de recursos |

---

## 📤 Salidas (Outputs)

| Nombre | Tipo | Sensible | Descripción |
| :--- | :--- | :--- | :--- |
| `cluster_id` | `string` | No | ID del recurso de AKS en Azure |
| `cluster_name` | `string` | No | Nombre del clúster |
| `oidc_issuer_url` | `string` | No | URL del emisor OIDC para asociar ServiceAccounts con identidades federadas |
| `kubelet_identity_object_id` | `string` | No | Object ID de la identidad administrada asignada al Kubelet |
| `kubelet_identity_client_id` | `string` | No | Client ID de la identidad administrada asignada al Kubelet |
| `cluster_identity_principal_id` | `string` | No | Principal ID de la identidad SystemAssigned del clúster |
| `kube_config_raw` | `string` | **Sí** | Configuración kubeconfig completa para conectarse al clúster |
| `host` | `string` | **Sí** | Endpoint URL del Kubernetes API Server |
| `client_certificate` | `string` | **Sí** | Certificado TLS de autenticación de cliente |
| `client_key` | `string` | **Sí** | Llave privada TLS de autenticación de cliente |
| `cluster_ca_certificate` | `string` | **Sí** | Certificado raíz de la CA del clúster |

> **¿Por qué `kube_config` y sus credenciales son marcados como `sensitive = true`?**
> En Terraform, marcar un valor como `sensitive` instruye al CLI a ocultar su contenido en `stdout` durante `terraform plan`, `terraform apply` y pipelines de CI/CD. El kubeconfig contiene claves privadas y certificados TLS de administrador de cluster que otorgarían acceso privilegiado ilimitado (`cluster-admin`) a cualquiera que lea los logs de compilación o ejecución.

---

## 🔒 Postura de Seguridad y Análisis Checkov

El módulo ha sido validado con **Checkov 3.x** con **0 fallos**:
* `CKV_AZURE_169` (Scale sets): Habilitado.
* `CKV_AZURE_5` (RBAC): Habilitado.
* `CKV_AZURE_7` (Network Policy): Habilitado vía Cilium.
* `CKV_AZURE_8` (Dashboard): Deshabilitado.
* `CKV_AZURE_168` (Mínimo 50 pods): Configurado con `max_pods = 50`.
* `CKV_AZURE_246` (HTTP application routing): Deshabilitado.
* `CKV_AZURE_143` (Sin IPs públicas en nodos): Cumplido.
* `CKV_AZURE_171` (Upgrade channel): Configurado en `"patch"`.
* `CKV_AZURE_116` (Azure Policy Add-on): Habilitado.
* `CKV2_AZURE_29` (Azure CNI): Habilitado en modo Overlay.

Las políticas no aplicables al entorno de laboratorio personal (como clústeres completamente privados que requerirían VPN/ExpressRoute, Defender for Containers que genera un costo de $7/nodo/mes, o Customer-Managed Keys que requieren servicios de cifrado dedicados adicionales) están documentadas y suprimidas con sus respectivas justificaciones técnicas dentro del código Terraform.
