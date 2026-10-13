# Recursos creados con az CLI antes de existir este stack. Tras el primer
# apply estos bloques no hacen nada.

import {
  to = azurerm_resource_group.ci
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-devops-sre-ci-eastus2"
}

import {
  to = azurerm_container_registry.acr
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-devops-sre-ci-eastus2/providers/Microsoft.ContainerRegistry/registries/acrdevsrelab01"
}

import {
  to = azuread_application.ci
  id = "/applications/73a6aea7-fbc1-445b-be7d-66fc5109328a"
}

import {
  to = azuread_service_principal.ci
  id = "/servicePrincipals/37281f1a-0a21-45a7-a8ac-38b36907fb9e"
}

# Formato: {object id de la app}/federatedIdentityCredential/{id de la credencial}
import {
  for_each = {
    "gh-pr-standard"    = "d570aee4-3321-4af5-8091-1a451e32e8cf"
    "gh-pr-immutable"   = "21571889-ed34-401a-81b7-4ac2df292cea"
    "gh-main-standard"  = "fc2027a3-d71b-4d50-a692-6f1746d39fbd"
    "gh-main-immutable" = "79267b2e-4b3c-4a0a-ab2b-b61869a0f682"
  }

  to = azuread_application_federated_identity_credential.ci[each.key]
  id = "73a6aea7-fbc1-445b-be7d-66fc5109328a/federatedIdentityCredential/${each.value}"
}

import {
  to = azurerm_role_assignment.acr_push
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-devops-sre-ci-eastus2/providers/Microsoft.ContainerRegistry/registries/acrdevsrelab01/providers/Microsoft.Authorization/roleAssignments/d6bf2d7c-bf6d-4db6-b559-3dd10602b7d1"
}

import {
  to = azurerm_role_assignment.acr_reader
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-devops-sre-ci-eastus2/providers/Microsoft.ContainerRegistry/registries/acrdevsrelab01/providers/Microsoft.Authorization/roleAssignments/85a4522b-0c4a-417b-b35d-ef7ed31b1186"
}
