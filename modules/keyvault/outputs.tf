output "key_vault_id" {
  description = "ID del Azure Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Nombre del Azure Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI del Azure Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}
