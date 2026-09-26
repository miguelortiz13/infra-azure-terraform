# Módulo Monitoring (`modules/monitoring`)

Este módulo aprovisiona un **Azure Log Analytics Workspace** configurado de acuerdo con las mejores prácticas de observabilidad y control presupuestario (**FinOps**).

---

## 🎯 Capacidades Principales

1. **Retención Mínima Optimizada para Costos**:
   - `retention_in_days = 30`: 30 días es el período mínimo gratuito de retención incluido en el SKU `PerGB2018`. Evita cargos adicionales de almacenamiento prolongado en entornos de desarrollo y laboratorio.

2. **Límite Diario de Ingesta (Daily Cap)**:
   - `daily_quota_gb = 0.5`: Establece un tope diario máximo de 500 MB de ingesta de logs. Si una aplicación o servicio entra en un ciclo de logs descontrolado, Azure detiene la ingesta al alcanzar este tope para proteger el presupuesto de $20 USD/mes.

3. **Compatibilidad con Agentes y Métricas**:
   - Expone tanto el ID del recurso de Azure como el `workspace_guid` y `primary_shared_key` necesarios para conectar Container Insights, Prometheus, OpenTelemetry Collector o Fluent Bit.

---

## 📋 Variables de Entrada (Inputs)

| Nombre | Tipo | Default | Descripción |
| :--- | :--- | :--- | :--- |
| `workspace_name` | `string` | N/A *(requerido)* | Nombre del Log Analytics Workspace |
| `resource_group_name` | `string` | N/A *(requerido)* | Nombre del Resource Group donde residirá el Workspace |
| `location` | `string` | N/A *(requerido)* | Región de Azure |
| `sku` | `string` | `"PerGB2018"` | SKU del Workspace (`PerGB2018`) |
| `retention_in_days` | `number` | `30` | Días de retención de datos (mínimo 30) |
| `daily_quota_gb` | `number` | `0.5` | Tope diario de ingesta en GB (-1 para ilimitado) |
| `tags` | `map(string)` | `{}` | Etiquetas de recursos |

---

## 📤 Salidas (Outputs)

| Nombre | Tipo | Sensible | Descripción |
| :--- | :--- | :--- | :--- |
| `workspace_id` | `string` | No | ID del recurso de Log Analytics en Azure |
| `workspace_guid` | `string` | No | Identificador GUID del workspace (`workspace_id`) |
| `workspace_name` | `string` | No | Nombre del workspace |
| `primary_shared_key` | `string` | **Sí** | Clave compartida primaria para autenticación de agentes |
