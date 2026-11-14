# Application Insights is workspace-based with local auth disabled: telemetry is
# only accepted with an Entra token from a managed identity.
resource "azurerm_application_insights" "this" {
  name                         = local.names.app_insights
  location                     = var.location
  resource_group_name          = var.resource_group_name
  application_type             = "web"
  workspace_id                 = var.log_analytics_workspace_id
  local_authentication_enabled = false
  tags                         = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = {
    key_vault  = azurerm_key_vault.this.id
    speech     = azurerm_cognitive_account.speech.id
    translator = azurerm_cognitive_account.translator.id
    api        = azurerm_windows_web_app.api.id
  }

  name                       = "diag-to-law"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}
