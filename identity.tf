# The API's user-assigned identity. Every data-plane permission is an RBAC role
# on this identity, so no keys or connection strings are needed anywhere.
resource "azurerm_user_assigned_identity" "this" {
  name                = local.names.identity
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  role_assignments = {
    speech_user = {
      scope = azurerm_cognitive_account.speech.id
      role  = "Cognitive Services Speech User"
    }
    translator_user = {
      scope = azurerm_cognitive_account.translator.id
      role  = "Cognitive Services User"
    }
    data_blob = {
      scope = azurerm_storage_account.data.id
      role  = "Storage Blob Data Contributor"
    }
    kv_secrets = {
      scope = azurerm_key_vault.this.id
      role  = "Key Vault Secrets User"
    }
    # Application Insights has local (key) auth disabled, so telemetry is
    # sent with an Entra token.
    appi_publisher = {
      scope = azurerm_application_insights.this.id
      role  = "Monitoring Metrics Publisher"
    }
  }
}

resource "azurerm_role_assignment" "identity" {
  for_each = local.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
}
