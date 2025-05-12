output "id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.main.ip_address
}

output "backend_address_pool_ids" {
  description = "List of backend address pool IDs"
  value       = azurerm_application_gateway.main.backend_address_pool.*.id
}