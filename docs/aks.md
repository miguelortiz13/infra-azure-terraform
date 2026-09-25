# Arquitectura y Diseño de AKS (`infra-azure-terraform`)

Este documento detalla las decisiones arquitectónicas, de red, identidad, seguridad y costos para los clústeres de **Azure Kubernetes Service (AKS)** en los entornos `dev` y `prod`.

---

## 1. Topología y Red

```
+-------------------------------------------------------------------------------+
| Azure Virtual Network (10.10.0.0/16 - dev)                                    |
|                                                                               |
|  +-------------------------------------+  +--------------------------------+  |
|  | Subnet: snet-aks (10.10.0.0/22)     |  | Subnet: snet-gateway           |  |
|  | - Nodes VMs (e.g. 10.10.0.4, 0.5)   |  | (10.10.4.0/24)                 |  |
|  |   ScaleSet VMSS                     |  | Application Gateway / Ingress  |  |
|  +-------------------------------------+  +--------------------------------+  |
|                     |                                                         |
|         Azure CNI Overlay (eBPF)                                              |
|                     v                                                         |
|  +-------------------------------------+  +--------------------------------+  |
|  | Pod CIDR (10.244.0.0/16)            |  | Service CIDR (10.0.0.0/16)     |  |
|  | - boutique microservices            |  | - CoreDNS (10.0.0.10)          |  |
|  | - system & monitoring pods          |  | - ClusterIPs de servicios      |  |
|  +-------------------------------------+  +--------------------------------+  |
+-------------------------------------------------------------------------------+
                               |
                   Role: AcrPull (RBAC)
                               v
               +-------------------------------+
               | Azure Container Registry (ACR)|
               | acrdevopssredev<suffix>       |
               +-------------------------------+
```

### 1.1 ¿Por qué Azure CNI Overlay?
- En Azure CNI clásico, cada Pod consume una dirección IP directamente de la subnet de la VNet. Para un cluster con decenas de réplicas y microservicios, se requieren subnets masivas (`/20` o `/19`) y suele generar agotamiento prematuro de direccionamiento IP privado.
- En **Azure CNI Overlay**, solo los **nodos** consumen IPs de la VNet (`snet-aks`). Los **Pods** reciben direcciones de un espacio privado enrutado internamente (`10.244.0.0/16`) administrado mediante encapsulamiento overlay. Esto combina el rendimiento de Azure CNI con la conservación de IPs de Kubenet.

### 1.2 ¿Por qué Cilium como Data Plane y Network Policy?
- Cilium reemplaza el filtrado tradicional basado en `iptables` por programas eBPF cargados directamente en el kernel de Linux.
- Brinda mayor escalabilidad y latencia reducida.
- Permite la aplicación de políticas de red a nivel de Capa 3/4 y Capa 7, preparando el entorno para las prácticas de seguridad de red avanzadas en P6.

---

## 2. Identidad y Control de Acceso

### 2.1 Managed Identity vs Service Principal
- El clúster utiliza una **SystemAssigned Managed Identity** para el plano de control y una **Kubelet Managed Identity** para las operaciones de los nodos.
- No existen secretos de cliente (`client_secret`), ni certificados que requieran rotación manual o puedan filtrarse en repositorios.

### 2.2 Integración con Azure Container Registry (`AcrPull`)
- El módulo asigna automáticamente el rol `AcrPull` de Azure RBAC sobre el ACR del proyecto usando el `object_id` de la identidad del Kubelet:
  ```hcl
  resource "azurerm_role_assignment" "aks_acr_pull" {
    principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
    role_definition_name             = "AcrPull"
    scope                            = var.acr_id
    skip_service_principal_aad_check = true
  }
  ```
- Esto permite desplegar pods que referencian imágenes del registro privado sin tener que configurar `imagePullSecrets` en los manifiestos de Kubernetes.

### 2.3 Workload Identity & OIDC
- Se configuran `oidc_issuer_enabled = true` y `workload_identity_enabled = true`.
- Con esto, AKS expone una URL de descubrimiento OIDC (`oidc_issuer_url`).
- En proyectos futuros (P3, P6, P7), un pod que requiera acceder a Azure Key Vault o Azure Storage no utilizará credenciales fijas: una ServiceAccount de Kubernetes intercambiará un token federado firmado por el clúster con Azure Entra ID para asumir una Managed Identity con permisos mínimos.

---

## 3. Estrategia FinOps (Control de Costos)

| Parámetro | Configuración | Justificación FinOps |
| :--- | :--- | :--- |
| `sku_tier` | `"Free"` | Ahorra ~$73 USD/mes al evitar el cargo por SLA de tiempo de actividad en desarrollo |
| `vm_size` | `"Standard_D2as_v6"` | 2 vCPUs AMD EPYC y 8 GiB de RAM por ~$0.088 USD/h (~$0.26 USD por sesión de 3h) |
| Autoscaling | `min: 1`, `max: 3` | Inicia con 1 solo nodo. Si se despliega la carga de Boutique, escala a 2 nodos según demanda |

| `os_disk_size_gb` | `30` | El default de AKS es 128 GB. Reducir a 30 GB ahorra costo de disco administrado |
| Microsoft Defender | Deshabilitado | Evita un costo recurrente de ~$7 USD/nodo/mes |

---

## 4. Sensibilidad de Datos y Salidas

El kubeconfig del clúster (`kube_config_raw`, `client_certificate`, `client_key`, `cluster_ca_certificate`) está marcado como `sensitive = true` en Terraform.
Esto previene que credenciales administrativas con privilegios totales sobre el plano de control de Kubernetes se impriman en texto plano en consolas de terminal o en registros de auditoría de CI/CD.
