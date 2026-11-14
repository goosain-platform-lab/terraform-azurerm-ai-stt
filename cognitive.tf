# Speech and Translator. Key auth is disabled on both: callers authenticate
# with Entra ID, which requires a custom subdomain.
resource "azurerm_cognitive_account" "speech" {
  name                          = local.names.speech
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "SpeechServices"
  sku_name                      = var.speech_sku
  custom_subdomain_name         = local.names.speech
  local_auth_enabled            = false
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account" "translator" {
  name                          = local.names.translator
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "TextTranslation"
  sku_name                      = var.translator_sku
  custom_subdomain_name         = local.names.translator
  local_auth_enabled            = false
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}
