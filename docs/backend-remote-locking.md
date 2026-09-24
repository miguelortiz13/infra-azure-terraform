# Backend Remoto y Bloqueo de Estado (State Locking) en Azure

> Documentación de arquitectura y verificación del estado remoto para [infra-azure-terraform](../README.md).

---

## 1. ¿Por qué Estado Remoto y Bloqueo?

El archivo `terraform.tfstate` contiene el mapeo exacto entre el código declarativo y los recursos reales en la nube de Azure. Contiene metadatos sensibles (IDs, endpoints, secretos) y es la fuente de verdad.

* **Riesgo del estado local:** Si el archivo se guarda localmente, no puede compartirse con el equipo ni usarse en pipelines de CI/CD sin riesgo de sobreescritura accidental.
* **Corrupción por concurrencia:** Si dos desarrolladores o dos ejecuciones de un pipeline ejecutan `terraform apply` al mismo tiempo, el estado puede corromperse irreversiblemente si no existe un mecanismo de exclusión mutua.

---

## 2. El problema del "Huevo y la Gallina" (*Bootstrap*)

Para que Terraform pueda almacenar su estado en un Storage Account de Azure, ese Storage Account primero debe existir.

Por esta razón, la arquitectura del repositorio se divide en dos fases:

1. **`bootstrap/` (Excepción controlada):**
   * Se ejecuta una única vez de forma local para aprovisionar:
     * El Resource Group `rg-devops-sre-tfstate`.
     * El Storage Account `stdevsretf<suffix>` con TLS 1.2, cifrado, versionado y retención de 7 días.
     * El contenedor de blobs `tfstate`.
     * El rol RBAC `Storage Blob Data Owner` para el usuario/identidad.
   * Su estado se conserva en `bootstrap/terraform.tfstate` (ignorado en git pero respaldado).

2. **Entornos (`envs/dev`, `envs/prod`):**
   * Configuran el bloque `backend "azurerm"` apuntando al Storage Account creado por el bootstrap:
     ```hcl
     terraform {
       backend "azurerm" {
         resource_group_name  = "rg-devops-sre-tfstate"
         storage_account_name = "stdevsretfufbmga"
         container_name       = "tfstate"
         key                  = "dev.tfstate"
         use_azuread_auth     = true
       }
     }
     ```
   * Utilizan **autenticación moderna Entra ID (Azure AD)** sin necesidad de exponer ni almacenar access keys en el código (`use_azuread_auth = true`).

---

## 3. Cómo Funciona el State Locking en Azure Blob Storage

Azure Storage implementa el bloqueo a través de **Blob Leases**:

1. Cuando un comando de Terraform (`plan`, `apply`, `destroy`) inicia, solicita un **Lease exclusivo** sobre el blob del estado (`dev.tfstate`).
2. Azure Blob Storage marca el lease como `locked` y devuelve un ID de Lease único que Terraform registra temporalmente en los metadatos del blob.
3. Si otro proceso intenta ejecutar una acción sobre el mismo entorno mientras el lease está activo, la API de Azure rechaza la adquisición del lease y Terraform detiene la ejecución inmediatamente:
   ```text
   Acquiring state lock. This may take a few moments...
   Error: Error acquiring the state lock
   Error message: state blob is already locked
   ```
4. Al finalizar la ejecución con éxito o error controlado, Terraform libera el lease (`unlocked`), permitiendo la siguiente ejecución.

---

## 4. Prueba y Verificación Realizada

Durante la fase de construcción de **P1-03**, se ejecutó la siguiente prueba de estrés para validar el comportamiento del bloqueo:

1. **Adquisición artificial del Lease:**
   Se adquirió un Lease temporal de 30 segundos sobre `dev.tfstate` usando Azure CLI:
   ```bash
   az storage blob lease acquire \
     --account-name "stdevsretfufbmga" \
     --container-name "tfstate" \
     --name "dev.tfstate" \
     --lease-duration 30 \
     --auth-mode login
   ```

2. **Intento concurrente con Terraform:**
   Se ejecutó `terraform plan` con timeout de 3 segundos en `envs/dev`:
   ```bash
   cd envs/dev && terraform plan -lock-timeout=3s
   ```
   * **Resultado observado:** Terraform esperó los 3 segundos configurados y abortó la operación con el error `Error acquiring the state lock: state blob is already locked`, impidiendo cualquier modificación concurrente.

3. **Liberación y reanudación:**
   Tras liberarse el lease en Azure Storage, se reejecutó el comando:
   ```bash
   cd envs/dev && terraform plan
   ```
   * **Resultado observado:** Terraform adquirió el lock exitosamente, comparó el estado y liberó el lock al terminar:
   ```text
   Acquiring state lock. This may take a few moments...
   No changes. Your infrastructure matches the configuration.
   Releasing state lock. This may take a few moments...
   ```

---

## 5. Procedimiento ante un Bloqueo Huérfano (*Stuck Lock*)

Si un pipeline de CI/CD se cancela abruptamente mientras ejecutaba `terraform apply`, el lease puede quedar retenido temporalmente. Para desbloquearlo:

1. **Opción recomendada por Terraform:**
   ```bash
   cd envs/dev && terraform force-unlock <LOCK-ID>
   ```

2. **Opción administrativa mediante Azure CLI (romper el lease):**
   ```bash
   az storage blob lease break \
     --account-name "<storage-account>" \
     --container-name "tfstate" \
     --name "dev.tfstate" \
     --auth-mode login
   ```
