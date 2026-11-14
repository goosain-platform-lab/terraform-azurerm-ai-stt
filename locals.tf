data "azurerm_client_config" "current" {}

locals {
  # Short region codes used in names. Unknown regions fall back to the full name.
  region_codes = {
    southafricanorth   = "zan"
    southafricawest    = "zaw"
    westeurope         = "weu"
    northeurope        = "neu"
    swedencentral      = "sdc"
    uksouth            = "uks"
    francecentral      = "frc"
    germanywestcentral = "gwc"
    switzerlandnorth   = "szn"
    eastus             = "eus"
    eastus2            = "eus2"
  }

  region = lookup(local.region_codes, var.location, var.location)

  # <type>-<workload>-<environment>-<region>[suffix]
  base = "${var.workload}-${var.environment}-${local.region}${var.unique_suffix}"

  names = {
    identity     = "id-${local.base}"
    key_vault    = "kv-${local.base}"
    app_insights = "appi-${local.base}"
    speech       = "spch-${local.base}"
    translator   = "trsl-${local.base}"
    # Storage accounts: lowercase letters and digits only, max 24 characters.
    storage_data = substr("st${var.workload}data${var.environment}${local.region}${var.unique_suffix}", 0, 24)
    plan         = "asp-${local.base}"
    api          = "app-${var.workload}-api-${var.environment}-${local.region}${var.unique_suffix}"
    web          = "app-${var.workload}-web-${var.environment}-${local.region}${var.unique_suffix}"
  }
}
