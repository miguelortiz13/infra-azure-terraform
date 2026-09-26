# Ciclo de Vida del Entorno Dev: Aprovisionamiento, Humo, Drift y Destrucción

Este documento registra la evidencia de ejecución del ciclo completo de vida de la infraestructura de desarrollo (`apply` → prueba de humo en la nube → detección de drift → `destroy`) conforme a los requisitos de la tarea **P1-07**.

---

## 1. Métricas de Tiempo y Composición de Módulos

El entorno de desarrollo integra todos los módulos de infraestructura pasando outputs entre sí:
- **`modules/network`**: VNet `10.10.0.0/16`, subnets (`snet-aks`, `snet-gateway`, `snet-endpoints`), NSGs y asociaciones.
- **`modules/acr`**: Azure Container Registry con autenticación basada exclusivamente en Entra ID RBAC.
- **`modules/keyvault`**: Key Vault con autorización RBAC y secreto de prueba.
- **`modules/monitoring`**: Log Analytics Workspace (`PerGB2018`, retención de 30 días, daily cap de 0.5 GB).
- **`modules/aks`**: Cluster AKS con Azure CNI Overlay, plano de datos y políticas de red Cilium eBPF, emisor OIDC y Workload Identity activados, agente OMS conectado a Log Analytics Workspace, y asignación de rol `AcrPull` de la kubelet identity sobre el ACR.

### ⏱️ Tiempos Medidos
- **`terraform apply` (creación completa de 19 recursos desde cero):** **371 segundos (6 minutos 11 segundos)**.
- **`helm upgrade --install` (despliegue de los 12 microservicios de Online Boutique):** **~3 minutos**.
- **`terraform destroy` (eliminación total sin residuos):** **~5 minutos 30 segundos**.

---

## 2. Prueba de Humo en la Nube (Online Boutique en AKS)

Se desplegó Google Online Boutique utilizando el Chart oficial `0.10.6` en el namespace `boutique`:
```bash
helm upgrade --install onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
  --version 0.10.6 \
  --kube-context aks-devops-sre-dev-eastus2 \
  --namespace boutique --create-namespace \
  -f values/onlineboutique.yaml --wait --timeout 10m
```

### 🔬 Observación de Cluster Autoscaler
- Al desplegar la carga completa de 12 microservicios, el nodo inicial saturó su CPU reservada.
- El **Cluster Autoscaler** de AKS detectó pods en estado `FailedScheduling (Insufficient cpu)` y escaló automáticamente el Virtual Machine Scale Set (`aks-system-29022327-vmss`) de **1 a 3 nodos** (`cloudProviderTarget: 3`).
- Los nuevos nodos se incorporaron en estado `Ready` y los pods se distribuyeron y ejecutaron exitosamente.

### 🧪 Resultado del Smoke Test
Se ejecutó la prueba de humo mediante `scripts/smoke-test.sh`:
```bash
CONTEXT=aks-devops-sre-dev-eastus2 NAMESPACE=boutique scripts/smoke-test.sh
```
**Resultado:**
```text
smoke OK: frontend respondió 200 (intento 9)
```

---

## 3. Detección y Gestión de Drift

### 3.1 Simulación de Cambio Fuera de Banda
Se simuló un cambio manual en el portal añadiendo una etiqueta no gestionada en el Resource Group:
```bash
az group update --name rg-devops-sre-dev-eastus2 --set tags.portal_drift="manual_change_simulated"
```

### 3.2 Detección en `terraform plan`
Al ejecutar `terraform plan`, Terraform detectó y propuso corregir el desvío reconciliando el estado deseado:
```hcl
  # azurerm_resource_group.rg will be updated in-place
  ~ resource "azurerm_resource_group" "rg" {
      ~ tags = {
            "environment"  = "dev"
            "managed_by"   = "terraform"
          - "portal_drift" = "manual_change_simulated" -> null
            "project"      = "devops-sre-lab"
        }
    }
```

### 3.3 Aprendizajes Clave de Ingeniería SRE
1. **Eviction por `ephemeral-storage` con discos pequeños:**
   Con un disco de SO de 30 GB, el espacio libre residual tras el sistema operativo base, kernel y paquetes containerd (~22 GB) puede caer bajo el umbral de desalojo de Kubernetes (10% o ~3 GB) al descargar múltiples imágenes pesadas. Se ajustó `os_disk_size_gb = 64` para garantizar ~40 GB libres para almacenamiento efímero sin riesgo de desalojo.
2. **Ciclo de vida del Cluster Autoscaler vs Terraform:**
   Cuando el autoscaler escala los nodos de 1 a 3, Terraform interpreta el cambio como drift (`node_count = 3 -> 1`). Se implementó en el módulo AKS:
   ```hcl
   lifecycle {
     ignore_changes = [
       default_node_pool[0].node_count,
       default_node_pool[0].upgrade_settings
     ]
   }
   ```
   permitiendo que el autoscaler de Kubernetes opere libremente sin que Terraform intente revertir la escala.

---

## 4. Costo Real de la Sesión (FinOps)

- **Duración activa del laboratorio:** ~40 minutos.
- **Recursos utilizados:**
  - AKS Control Plane: $0.00 USD (Free Tier).
  - Cómputo VMs (`Standard_D2as_v6`, 1 nodo base escalado a 3 durante la prueba de 10 min): ~$0.15 USD.
  - Almacenamiento Discos SO y ACR: ~$0.02 USD.
  - Ingesta Log Analytics (< 50 MB en la prueba): $0.00 USD.
- **Gasto total aproximado de la sesión:** **~$0.17 USD** (bien por debajo del presupuesto mensual de $20 USD).
