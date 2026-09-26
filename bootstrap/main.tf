data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "stdevsretf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# Asignar Storage Blob Data Owner al usuario actual para autenticacion Entra ID / Azure AD
resource "azurerm_role_assignment" "blob_owner" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC: Identidad Federada sin Secretos Estáticos (P1-08)
# -----------------------------------------------------------------------------

resource "azuread_application" "github_actions" {
  display_name = var.github_actions_app_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

# Credencial federada 1: Pull Requests (formato inmutable)
resource "azuread_application_federated_identity_credential" "pr" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-pull-request"
  description    = "OIDC federation for pull requests (immutable format)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository_immutable}:pull_request"
}

# Credencial federada 2: Rama main (formato inmutable)
resource "azuread_application_federated_identity_credential" "main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-branch-main"
  description    = "OIDC federation for main branch workflow runs (immutable format)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository_immutable}:ref:refs/heads/main"
}

# Credencial federada 3: Environment dev (formato inmutable)
resource "azuread_application_federated_identity_credential" "dev" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-env-dev"
  description    = "OIDC federation for dev environment (immutable format)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository_immutable}:environment:dev"
}

# Rol 1: Contributor en la suscripción para aprovisionar y gestionar recursos
resource "azurerm_role_assignment" "gh_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Rol 2: Storage Blob Data Contributor sobre el Storage Account del estado remoto de Terraform
resource "azurerm_role_assignment" "gh_storage_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Rol 3: User Access Administrator en la suscripción para crear role assignments de Terraform (AcrPull, Secrets Officer)
resource "azurerm_role_assignment" "gh_user_access_admin" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_actions.object_id
}
