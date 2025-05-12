output "id" {
  description = "ID of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
}

output "name" {
  description = "Name of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].name : azurerm_windows_function_app.main[0].name
}

output "default_hostname" {
  description = "Default hostname of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname
}

output "principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].principal_id : azurerm_windows_function_app.main[0].identity[0].principal_id
}

output "os_type" {
  description = "OS type of the Function App"
  value       = var.os_type
}