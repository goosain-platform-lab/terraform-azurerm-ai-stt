# Windows plan for the two real-time apps. The batch module can join this
# plan (output shared_services.app_service_plan_id) instead of paying for its own.
#   api - .NET 8 SignalR hub for real-time translation (the browser connects here)
#   web - Blazor WebAssembly front end (static files)
resource "azurerm_service_plan" "this" {
  name                = local.names.plan
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.app_service_plan_sku
  tags                = var.tags
}

locals {
  # Non-secret settings. Every service is reached with the managed identity
  # named by AZURE_CLIENT_ID, so none of these values is a credential.
  api_settings = {
    AZURE_CLIENT_ID                           = azurerm_user_assigned_identity.this.client_id
    APPLICATIONINSIGHTS_CONNECTION_STRING     = azurerm_application_insights.this.connection_string
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "Authorization=AAD;ClientId=${azurerm_user_assigned_identity.this.client_id}"
    Speech__Endpoint                          = azurerm_cognitive_account.speech.endpoint
    Speech__Region                            = var.location
    Speech__ResourceId                        = azurerm_cognitive_account.speech.id
    Translator__Endpoint                      = azurerm_cognitive_account.translator.endpoint
    Translator__Region                        = var.location
    Storage__BlobServiceUri                   = azurerm_storage_account.data.primary_blob_endpoint
    KeyVault__Uri                             = azurerm_key_vault.this.vault_uri
  }

  # Key Vault references: the app resolves the secret at runtime with its
  # managed identity. Only the vault name and secret name live in Terraform.
  api_kv_settings = {
    for setting, secret in var.api_key_vault_references :
    setting => "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=${secret})"
  }
}

resource "azurerm_windows_web_app" "api" {
  name                                           = local.names.api
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  public_network_access_enabled                  = var.api_public_network_access_enabled
  virtual_network_subnet_id                      = var.app_subnet_id
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.this.id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  # SignalR without a backplane needs sticky sessions.
  client_affinity_enabled = true
  tags                    = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    always_on              = true
    websockets_enabled     = true
    vnet_route_all_enabled = true
    use_32_bit_worker      = false
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }

    cors {
      allowed_origins     = ["https://${azurerm_windows_web_app.web.default_hostname}"]
      support_credentials = true
    }
  }

  app_settings = merge(local.api_settings, local.api_kv_settings)

  depends_on = [azurerm_role_assignment.identity]
}

resource "azurerm_windows_web_app" "web" {
  name                                           = local.names.web
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  public_network_access_enabled                  = var.web_public_network_access_enabled
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  tags                                           = var.tags

  site_config {
    always_on           = false
    use_32_bit_worker   = false
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  # Blazor WebAssembly runs in the browser, so nothing here may be secret.
  app_settings = {}
}
