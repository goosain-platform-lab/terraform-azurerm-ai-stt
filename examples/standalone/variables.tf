variable "location" {
  description = "Azure region for the deployment."
  type        = string
  default     = "southafricanorth"
}

variable "environment" {
  description = "Environment token used in names."
  type        = string
  default     = "lab"
}

variable "unique_suffix" {
  description = "Optional 0-4 character suffix for globally unique names."
  type        = string
  default     = ""
}

variable "address_space" {
  description = "VNet address space (a /26 is enough)."
  type        = string
  default     = "10.30.0.0/26"
}

variable "hub_virtual_network_id" {
  description = "Optional hub VNet to peer with (spoke side only; the hub owner creates the return peering)."
  type        = string
  default     = null
}

variable "use_hub_gateway" {
  description = "Route on-premises traffic through the hub's VPN/ExpressRoute gateway."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log Analytics retention."
  type        = number
  default     = 30
}

variable "log_daily_quota_gb" {
  description = "Daily ingestion cap in GB (-1 for no cap). A cap keeps lab costs predictable."
  type        = number
  default     = 1
}

variable "app_service_plan_sku" {
  description = "Windows App Service plan SKU."
  type        = string
  default     = "B1"
}

variable "api_key_vault_references" {
  description = "API app setting => Key Vault secret name, for secrets an operator adds by hand."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Extra tags merged onto the defaults."
  type        = map(string)
  default     = {}
}
