output "id" {
  description = "ID of the API Management service"
  value       = azurerm_api_management.main.id
}

output "name" {
  description = "Name of the API Management service"
  value       = azurerm_api_management.main.name
}

output "gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = azurerm_api_management.main.gateway_url
}

output "principal_id" {
  description = "Principal ID of the API Management service managed identity"
  value       = azurerm_api_management.main.identity[0].principal_id
}