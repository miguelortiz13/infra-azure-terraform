# ADR-0003 — Estructura de Módulos Desacoplados, Entornos Aislados y Backend Remoto

- **Estado:** aceptado
- **Fecha:** 2026-09-24

## Contexto

La infraestructura de Azure abarca redes (VNet, Subnets, NSG), cómputo de contenedores (AKS), registro de artefactos (ACR), gestión de secretos (Key Vault) y observabilidad (Log Analytics). Se requiere una estructura de código que permita reutilización, aislamiento de entornos (`dev` / `prod`) y concurrencia segura sin riesgo de corrupción de estado.

## Opciones consideradas

| Opción | A favor | En contra |
|---|---|---|
| **Monolito en raíz (`main.tf` único)** | Rápido de escribir al inicio. | Imposible de reutilizar; acoplamiento total; riesgo de destruir recursos de producción al modificar desarrollo; blast radius máximo. |
| **Workspaces de Terraform en un solo directorio** | Reutiliza el mismo código para varios entornos. | Variables fuertemente acopladas; no permite diferenciar configuraciones arquitectónicas sustanciales entre entornos (e.g. multi-node vs single-node); riesgo de aplicar al workspace equivocado. |
| **Módulos Reutilizables + Directorios de Entorno (`envs/`) + Backend Remoto dedicado** | Blast radius mínimo; separación de estado por entorno (`dev.tfstate`, `prod.tfstate`); módulos independientes y testeables; state locking distribuido con Azure Blob Leases. | Requiere resolver el problema del huevo y la gallina mediante un paso de `bootstrap/`. |

## Decisión

Adoptar una arquitectura de **Módulos Independientes con Directorios de Entorno Aislados y Bootstrap**:

1. **`modules/`:** Cada componente (`network`, `aks`, `acr`, `keyvault`, `monitoring`) es un módulo autocontenido con sus propias variables, outputs y sin bloques de provider o backend hardcodeados.
2. **`envs/`:** Carpetas independientes (`envs/dev`, `envs/prod`) que componen los módulos e inyectan valores específicos de cada entorno.
3. **`bootstrap/` (Excepción controlada):** Se ejecuta una única vez localmente para crear el Resource Group `rg-devops-sre-tfstate`, el Storage Account y el contenedor Blob donde se alojarán los estados de todos los entornos.
4. **State Locking y RBAC:** El backend utiliza `azurerm` con `use_azuread_auth = true` y autenticación Entra ID, apoyándose en los Blob Leases nativos para bloqueo de concurrencia.

## Consecuencias

- Cada entorno tiene su propio archivo de estado y ciclo de vida de ejecución independiente (`terraform -chdir=envs/dev ...`).
- Los comandos estandarizados se encapsulan en el `Makefile` (`make init ENV=dev`, `make plan ENV=dev`).
- Si dos pipelines o desarrolladores ejecutan `apply` simultáneamente, el bloqueo de Azure Blob Storage rechaza la segunda ejecución protegiendo la integridad del estado.
