# Application data (audio uploads, transcripts). Shared keys are disabled and
# the account is reachable only through its private endpoint.
resource "azurerm_storage_account" "data" {
  name                             = local.names.storage_data
  location                         = var.location
  resource_group_name              = var.resource_group_name
  account_kind                     = "StorageV2"
  account_tier                     = "Standard"
  account_replication_type         = var.storage_replication_type
  min_tls_version                  = "TLS1_2"
  https_traffic_only_enabled       = true
  shared_access_key_enabled        = false
  default_to_oauth_authentication  = true
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
  local_user_enabled               = false
  public_network_access            = "Disabled"
  tags                             = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# storage_account_id creates containers through Azure Resource Manager, so this
# works from a runner that cannot reach the private data plane.
resource "azurerm_storage_container" "data" {
  for_each = toset(var.data_containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}
