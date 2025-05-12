output "id" {
  description = "ID of the App Service Environment"
  value       = azurerm_app_service_environment_v3.main.id
}

output "name" {
  description = "Name of the App Service Environment"
  value       = azurerm_app_service_environment_v3.main.name
}

output "dns_suffix" {
  description = "DNS suffix of the App Service Environment"
  value       = azurerm_app_service_environment_v3.main.dns_suffix
}