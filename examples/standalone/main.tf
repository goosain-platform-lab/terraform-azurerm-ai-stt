# Standalone speech-to-text deployment: its own small spoke network, private
# DNS and Log Analytics, then the STT workload module.
locals {
  region = lookup({
    southafricanorth = "zan"
    southafricawest  = "zaw"
    westeurope       = "weu"
    northeurope      = "neu"
    swedencentral    = "sdc"
    uksouth          = "uks"
  }, var.location, var.location)

  suffix = "${var.environment}-${local.region}${var.unique_suffix}"

  tags = merge({
    workload    = "stt"
    environment = var.environment
    managed_by  = "terraform"
    repo        = "terraform-azurerm-ai-stt"
  }, var.tags)

  # Two subnets carved from the /26.
  subnets = {
    app = cidrsubnet(var.address_space, 2, 0) # /28 App Service integration
    pe  = cidrsubnet(var.address_space, 1, 1) # /27 private endpoints
  }

  private_dns_zones = {
    blob      = "privatelink.blob.core.windows.net"
    vault     = "privatelink.vaultcore.azure.net"
    cognitive = "privatelink.cognitiveservices.azure.com"
  }
}

#------------------------------------------------------------------------------
# Resource groups (network kept apart from the workload)
#------------------------------------------------------------------------------
resource "azurerm_resource_group" "network" {
  name     = "rg-stt-network-${local.suffix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "workload" {
  name     = "rg-stt-${local.suffix}"
  location = var.location
  tags     = local.tags
}

#------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  name                         = "log-stt-${local.suffix}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.workload.name
  sku                          = "PerGB2018"
  retention_in_days            = var.log_retention_days
  daily_quota_gb               = var.log_daily_quota_gb
  local_authentication_enabled = false
  tags                         = local.tags
}

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = "vnet-stt-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = [var.address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-stt-app-${local.suffix}"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.app]

  delegation {
    name = "app-service"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "pe" {
  name                            = "snet-stt-pe-${local.suffix}"
  resource_group_name             = azurerm_resource_group.network.name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnets.pe]
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets

  name                = "nsg-stt-${each.key}-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.this["app"].id
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.this["pe"].id
}

resource "azurerm_virtual_network_peering" "to_hub" {
  count = var.hub_virtual_network_id == null ? 0 : 1

  name                      = "peer-stt-to-hub-${local.suffix}"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.hub_virtual_network_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = var.use_hub_gateway
}

#------------------------------------------------------------------------------
# Private DNS
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "this" {
  for_each = local.private_dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.private_dns_zones

  name                 = "link-${each.key}-${local.suffix}"
  private_dns_zone_id  = azurerm_private_dns_zone.this[each.key].id
  virtual_network_id   = azurerm_virtual_network.this.id
  registration_enabled = false
  tags                 = local.tags
}

#------------------------------------------------------------------------------
# Workload
#------------------------------------------------------------------------------
module "stt" {
  source = "../../"

  environment         = var.environment
  location            = var.location
  unique_suffix       = var.unique_suffix
  resource_group_name = azurerm_resource_group.workload.name
  tags                = local.tags

  app_subnet_id              = azurerm_subnet.app.id
  private_endpoint_subnet_id = azurerm_subnet.pe.id
  private_dns_zone_ids       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  app_service_plan_sku     = var.app_service_plan_sku
  api_key_vault_references = var.api_key_vault_references

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.this,
    azurerm_subnet_network_security_group_association.app,
    azurerm_subnet_network_security_group_association.pe,
  ]
}
