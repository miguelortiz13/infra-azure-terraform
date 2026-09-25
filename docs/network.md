# Planificación de Red y Arquitectura de Subnets (Network)

> Documentación de arquitectura de red para [infra-azure-terraform](../README.md).

---

## 1. Estrategia de Direccionamiento IP (CIDR)

La plataforma utiliza un esquema de direccionamiento privado bajo el estándar **RFC 1918**. Cada entorno posee un bloque `/16` dedicado para evitar solapamientos y facilitar futuras interconexiones (VNet Peering, VPN o ExpressRoute):

| Entorno | Espacio de Direcciones (VNet) | Total IPs | Propósito |
|---|---|---|---|
| **dev** | `10.10.0.0/16` | 65,536 | Entorno de desarrollo, pruebas y laboratorios |
| **prod** | `10.20.0.0/16` | 65,536 | Entorno de producción aislado |

---

## 2. Segmentación de Subnets (Entorno `dev`)

Azure reserva **5 direcciones IP** por cada subnet (las primeras 4 y la última: red, gateway, DNS x 2 y broadcast). El dimensionamiento de subnets en `10.10.0.0/16` se distribuye así:

```text
10.10.0.0/16 (VNet devops-sre-dev-vnet)
├── 10.10.0.0/22   ── snet-aks        (1024 IPs, 1019 útiles) ── Nodos y Pods de AKS (Azure CNI Overlay)
├── 10.10.4.0/24   ── snet-gateway    (256 IPs,  251 útiles)  ── Ingress / Gateway API (Envoy Gateway)
└── 10.10.5.0/24   ── snet-endpoints  (256 IPs,  251 útiles)  ── Private Endpoints (Key Vault, ACR, etc.)
```

### Detalle de Subnets

| Subnet | Prefijo CIDR | IPs Útiles | Uso y Justificación |
|---|---|---|---|
| **`snet-aks`** | `10.10.0.0/22` | 1,019 | Aloja los nodos del cluster AKS. Un `/22` proporciona suficiente espacio para crecimiento del cluster, node pools adicionales (system y user pools) y upgrades de nodos (*rolling updates* temporales). |
| **`snet-gateway`** | `10.10.4.0/24` | 251 | Reservada para balanceadores de carga de capa 7, ingress controllers o Envoy Gateway (Gateway API de P3). |
| **`snet-endpoints`** | `10.10.5.0/24` | 251 | Subnet aislada para interfaces de red privadas (Private Endpoints) de servicios PaaS gestionados (Key Vault, ACR, Blob Storage). |

---

## 3. Seguridad de Red (Network Security Groups - NSGs)

Cada subnet cuenta con un **Network Security Group (NSG)** asociado:

1. **Principio de Mínimo Privilegio:** Tráfico entrante por defecto cerrado (*Default Deny* desde Internet).
2. **Subnet Gateway:** Es la única autorizada a exponer puertos públicos controlados (HTTP 80 / HTTPS 443).
3. **Subnet AKS:** No expone puertos públicos directos a los nodos. Todo el tráfico entrante proviene exclusivamente del Gateway/Load Balancer.
4. **Subnet Endpoints:** Bloqueada para acceso externo; solo acepta conexiones originadas dentro de la VNet.
