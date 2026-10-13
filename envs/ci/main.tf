# Recursos persistentes de CI del laboratorio (P2, online-boutique-ci).
#
# A diferencia de envs/dev, este stack NO se destruye al apagar el lab: el
# registro guarda las imágenes firmadas y sus atestaciones. Se creó con az CLI
# (docs/acr-cosign.md de online-boutique-ci) y se importó aquí (imports.tf).
#
# Costo: ACR Basic ~USD 5/mes. Si se deja de usar P2, destruir este stack.

resource "azurerm_resource_group" "ci" {
  name     = "rg-devops-sre-ci-${var.location}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "acrdevsrelab01"
  resource_group_name = azurerm_resource_group.ci.name
  location            = azurerm_resource_group.ci.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

# Identidad de GitHub Actions para publicar y firmar imágenes (OIDC, sin secretos).
resource "azuread_application" "ci" {
  display_name     = "gh-online-boutique-ci"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "ci" {
  client_id = azuread_application.ci.client_id
}

locals {
  # GitHub emite el claim `sub` en formato estándar o inmutable según la
  # configuración del repo; se aceptan ambos.
  federated_subjects = {
    "gh-pr-standard"    = { subject = "repo:${var.github_repository}:pull_request", description = "GitHub Actions PR standard subject" }
    "gh-pr-immutable"   = { subject = "repo:${var.github_immutable_repository}:pull_request", description = "GitHub Actions PR immutable subject" }
    "gh-main-standard"  = { subject = "repo:${var.github_repository}:ref:refs/heads/main", description = "GitHub Actions main branch standard subject" }
    "gh-main-immutable" = { subject = "repo:${var.github_immutable_repository}:ref:refs/heads/main", description = "GitHub Actions main branch immutable subject" }
  }
}

resource "azuread_application_federated_identity_credential" "ci" {
  for_each = local.federated_subjects

  application_id = azuread_application.ci.id
  display_name   = each.key
  description    = each.value.description
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value.subject
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.ci.object_id
}

resource "azurerm_role_assignment" "acr_reader" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.ci.object_id
}
