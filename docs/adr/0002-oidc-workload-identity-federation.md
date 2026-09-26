# ADR-0002 — Autenticación GitHub Actions hacia Azure mediante OIDC (Workload Identity Federation)

- **Estado:** aceptado
- **Fecha:** 2026-09-25

## Contexto

Para que los workflows de CI/CD en GitHub Actions puedan ejecutar `terraform plan`, `terraform apply` o inspeccionar recursos en Azure, necesitan autenticarse contra Microsoft Entra ID (Azure AD). Almacenar credenciales en repositorios de código representa uno de los mayores vectores de fuga de datos en la industria.

## Opciones consideradas

| Opción | A favor | En contra |
|---|---|---|
| **Client Secret estático en GitHub Secrets** | Fácil de configurar inicialmente. | Credencial de larga duración (meses o años); si se filtra permite acceso no restringido; requiere rotación manual periódica; amplía la superficie de ataque. |
| **Certificado X.509 en GitHub Secrets** | Más seguro que contraseñas planas. | Complejidad de gestión de PKI, renovación de claves privadas y posible fuga de la clave privada almacenada en el runner. |
| **OpenID Connect (OIDC) con Identidad Federada** | **Cero secretos almacenados**; tokens JWT efímeros firmados por GitHub de máximo 1 hora de validez; confianza basada en claims criptográficos (`sub`, `iss`, `aud`); auditoría granular por commit/PR en logs de Entra ID. | Requiere configuración de App Registration y Federated Identity Credentials en Entra ID. |

## Decisión

Implementar **Workload Identity Federation (OIDC)** entre GitHub Actions y Microsoft Entra ID:

1. No se guarda ninguna contraseña o secreto estático en GitHub Secrets. Los identificadores de conexión (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) se almacenan como variables públicas del repositorio (`vars.*`).
2. Se configuraron credenciales federadas para los tres contextos requeridos:
   - `ref:refs/heads/main` (despliegue continuo).
   - `pull_request` (validación de cambios y generación de plan).
   - `environment:dev` (despliegue con compuerta de aprobación manual).
3. Se adoptó el formato inmutable estándar de GitHub (`repo:<owner>@<id>/<repo>@<id>:<context>`).

## Consecuencias

- Los jobs de GitHub Actions requieren explícitamente `permissions: { id-token: write, contents: read }`.
- Terraform utiliza variables nativas `ARM_USE_OIDC=true` y `ARM_USE_AZUREAD=true` para autenticar tanto el proveedor `azurerm` como el backend remoto de almacenamiento.
- Se elimina el mantenimiento y riesgo operativo derivado de la rotación de secretos.
