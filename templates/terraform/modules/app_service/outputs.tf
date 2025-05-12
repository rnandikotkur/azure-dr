output "id" {
  description = "ID of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
}

output "name" {
  description = "Name of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
}

output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
}

output "principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].principal_id : azurerm_windows_web_app.main[0].identity[0].principal_id
}

output "os_type" {
  description = "OS type of the App Service"
  value       = var.os_type
}