output "id" {
  description = "ID of the Container App"
  value       = azurerm_container_app.main.id
}

output "name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.main.name
}

output "latest_revision_name" {
  description = "Name of the latest revision"
  value       = azurerm_container_app.main.latest_revision_name
}

output "principal_id" {
  description = "Principal ID of the Container App managed identity"
  value       = azurerm_container_app.main.identity[0].principal_id
}

output "ingress_fqdn" {
  description = "FQDN of the Container App ingress"
  value       = azurerm_container_app.main.ingress[0].fqdn
}