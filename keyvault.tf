# Key Vault uses RBAC and is reachable only through its private endpoint.
# Terraform creates the vault but never writes secret values: anything that
# must stay a secret is added by an operator (see README) and consumed by the
# apps through Key Vault references.
resource "azurerm_key_vault" "this" {
  name                          = local.names.key_vault
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku
  rbac_authorization_enabled    = true
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
  tags                          = var.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}
