terraform {
  backend "azurerm" {
    resource_group_name  = "rg-devops-sre-tfstate"
    storage_account_name = "stdevsretfufbmga"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_azuread_auth     = true
  }
}
