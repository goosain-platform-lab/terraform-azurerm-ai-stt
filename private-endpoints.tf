# Every data service is reached over a private endpoint in the caller's VNet.
# Each endpoint registers itself in the matching private DNS zone.
locals {
  private_endpoints = {
    kv = {
      resource_id = azurerm_key_vault.this.id
      subresource = "vault"
      dns_zone    = "vault"
    }
    speech = {
      resource_id = azurerm_cognitive_account.speech.id
      subresource = "account"
      dns_zone    = "cognitive"
    }
    translator = {
      resource_id = azurerm_cognitive_account.translator.id
      subresource = "account"
      dns_zone    = "cognitive"
    }
    st-data-blob = {
      resource_id = azurerm_storage_account.data.id
      subresource = "blob"
      dns_zone    = "blob"
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  for_each = local.private_endpoints

  name                          = "pe-${each.key}-${local.base}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.private_endpoint_subnet_id
  custom_network_interface_name = "nic-pe-${each.key}-${local.base}"
  tags                          = var.tags

  private_service_connection {
    name                           = "psc-${each.key}-${local.base}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids[each.value.dns_zone]]
  }
}
