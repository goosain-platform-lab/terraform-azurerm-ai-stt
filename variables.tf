#------------------------------------------------------------------------------
# Naming and placement
#------------------------------------------------------------------------------
variable "workload" {
  description = "Workload token used in every resource name: <type>-<workload>-<environment>-<region>."
  type        = string
  default     = "stt"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.workload))
    error_message = "workload must be 2-8 lowercase letters or digits (it is also used in storage account names)."
  }
}

variable "environment" {
  description = "Environment token used in resource names."
  type        = string
  default     = "lab"
}

variable "location" {
  description = "Azure region for the workload (for example southafricanorth)."
  type        = string
}

variable "unique_suffix" {
  description = "Optional short suffix appended to globally unique names. Use it if a name is taken or was soft-deleted recently."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]{0,4}$", var.unique_suffix))
    error_message = "unique_suffix must be 0-4 lowercase letters or digits."
  }
}

variable "resource_group_name" {
  description = "Existing resource group that will hold the workload resources (created by the caller)."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Network wiring (bring your own VNet)
#------------------------------------------------------------------------------
variable "app_subnet_id" {
  description = "Subnet delegated to Microsoft.Web/serverFarms, used for App Service VNet integration."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet that holds the private endpoints."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs. Required keys: blob, vault, cognitive. Extra keys are ignored."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["blob", "vault", "cognitive"] : contains(keys(var.private_dns_zone_ids), k)])
    error_message = "private_dns_zone_ids must contain the keys blob, vault and cognitive."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace that receives diagnostics and backs Application Insights."
  type        = string
}

#------------------------------------------------------------------------------
# Services (defaults are production-grade SKUs)
#------------------------------------------------------------------------------
variable "speech_sku" {
  description = "SKU for the Speech service."
  type        = string
  default     = "S0"
}

variable "translator_sku" {
  description = "SKU for the Translator service."
  type        = string
  default     = "S1"
}

variable "app_service_plan_sku" {
  description = "Windows App Service plan SKU for the API and the front end (the batch module can share this plan)."
  type        = string
  default     = "B1"
}

variable "api_public_network_access_enabled" {
  description = "Allow public access to the real-time API (the browser connects to its SignalR hub)."
  type        = bool
  default     = true
}

variable "web_public_network_access_enabled" {
  description = "Allow public access to the Blazor front end."
  type        = bool
  default     = true
}

variable "api_key_vault_references" {
  description = "App settings on the API that resolve from Key Vault at runtime: app setting name => secret name. Terraform never sees the secret value."
  type        = map(string)
  default     = {}
}

variable "data_containers" {
  description = "Blob containers created on the data storage account."
  type        = list(string)
  default     = ["uploads", "results"]
}

variable "storage_replication_type" {
  description = "Replication for the data storage account."
  type        = string
  default     = "LRS"
}

variable "key_vault_sku" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "key_vault_purge_protection_enabled" {
  description = "Purge protection. Off for the lab so destroy/redeploy can reuse the name; turn on for production."
  type        = bool
  default     = false
}
