output "identity" {
  description = "User-assigned identity used by the API."
  value = {
    id           = azurerm_user_assigned_identity.this.id
    client_id    = azurerm_user_assigned_identity.this.client_id
    principal_id = azurerm_user_assigned_identity.this.principal_id
    name         = azurerm_user_assigned_identity.this.name
  }
}

output "key_vault" {
  description = "Key Vault for any secret that cannot be replaced by a managed identity."
  value = {
    id   = azurerm_key_vault.this.id
    name = azurerm_key_vault.this.name
    uri  = azurerm_key_vault.this.vault_uri
  }
}

output "endpoints" {
  description = "Service endpoints (none of these are secrets)."
  value = {
    speech     = azurerm_cognitive_account.speech.endpoint
    translator = azurerm_cognitive_account.translator.endpoint
    blob       = azurerm_storage_account.data.primary_blob_endpoint
  }
}

output "apps" {
  description = "App names and default host names."
  value = {
    api_name     = azurerm_windows_web_app.api.name
    api_hostname = azurerm_windows_web_app.api.default_hostname
    web_name     = azurerm_windows_web_app.web.name
    web_hostname = azurerm_windows_web_app.web.default_hostname
  }
}

output "shared_services" {
  description = "Everything the batch module (terraform-azurerm-ai-stt-batch) needs to plug into this workload."
  value = {
    speech_account_id       = azurerm_cognitive_account.speech.id
    speech_endpoint         = azurerm_cognitive_account.speech.endpoint
    speech_principal_id     = azurerm_cognitive_account.speech.identity[0].principal_id
    translator_account_id   = azurerm_cognitive_account.translator.id
    translator_endpoint     = azurerm_cognitive_account.translator.endpoint
    data_storage_account_id = azurerm_storage_account.data.id
    data_blob_endpoint      = azurerm_storage_account.data.primary_blob_endpoint
    key_vault_id            = azurerm_key_vault.this.id
    app_service_plan_id     = azurerm_service_plan.this.id
  }
}

output "application_insights_id" {
  description = "Application Insights resource ID."
  value       = azurerm_application_insights.this.id
}
