output "resource_groups" {
  description = "Resource groups created."
  value = {
    network  = azurerm_resource_group.network.name
    workload = azurerm_resource_group.workload.name
  }
}

output "identity" {
  description = "Managed identity used by the API."
  value       = module.stt.identity
}

output "key_vault" {
  description = "Key Vault name and URI."
  value       = module.stt.key_vault
}

output "apps" {
  description = "App names and host names."
  value       = module.stt.apps
}

output "endpoints" {
  description = "Service endpoints."
  value       = module.stt.endpoints
}
