# ADR-0001 — Azure CNI Overlay y Cilium eBPF como plano de datos y red para AKS

- **Estado:** aceptado
- **Fecha:** 2026-09-24

## Contexto

El clúster de Kubernetes en Azure (AKS) requiere un plugin de red (CNI) para la conectividad de los Pods entre nodos y hacia servicios externos. La elección del modelo de red impacta directamente en la escalabilidad del direccionamiento IP, el rendimiento del tráfico interno y las capacidades de seguridad (Network Policies).

## Opciones consideradas

| Opción | A favor | En contra |
|---|---|---|
| **Kubenet** | Conserva IPs de la VNet (los Pods usan NAT/enrutamiento en nodo). | Rendimiento inferior por múltiples saltos NAT, no soporta características avanzadas de red empresarial. |
| **Azure CNI Clásico (VNet Allocation)** | Cada Pod recibe una IP directa y enrutable de la VNet corporativa. | Agota rápidamente el espacio de direcciones IP de la VNet/Subnet (`max_pods` × número de nodos reservados por adelantado). |
| **Azure CNI Overlay + Cilium eBPF** | Los Pods usan un bloque CIDR privado superpuesto independiente (`10.244.0.0/16`), preservando IPs de la VNet; Cilium reemplaza `iptables` y `kube-proxy` por programas eBPF en el kernel de Linux con mínimo overhead y alto throughput. | Requiere nodo con kernel Linux moderno (soportado nativamente en Azure Linux / Ubuntu LTS de AKS). |

## Decisión

Adoptar **Azure CNI en modo Overlay** con **Cilium como plano de datos y políticas de red (`network_dataplane = "cilium"`, `network_policy = "cilium"`)**:

1. **Ahorro de IPs en VNet:** Permite desplegar decenas de microservicios y réplicas con una subnet compacta para nodos (`10.10.0.0/22`), evitando el sobrecosto y restricciones de asignación masiva de IPs privadas.
2. **Rendimiento eBPF:** Enrutamiento a nivel de kernel mediante BPF maps sin degradación lineal causada por miles de reglas en `iptables`.
3. **Seguridad Avanzada:** Soporte nativo para `CiliumNetworkPolicy` y aislamiento estricto entre namespaces sin requerir agentes CNI de terceros no administrados.

## Consecuencias

- Los Pods no son directamente accesibles por su IP desde fuera del clúster (el tráfico entrante debe ingresar mediante Ingress / Load Balancer o API Server proxy), lo cual es la mejor práctica de seguridad.
- La configuración del clúster fija `network_plugin = "azure"`, `network_plugin_mode = "overlay"` y `network_dataplane = "cilium"`.
