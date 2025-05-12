output "vnet_id" {
  description = "ID of the virtual network"
  value       = var.existing_vnet_id != "" ? var.existing_vnet_id : azurerm_virtual_network.main[0].id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = var.existing_vnet_id != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
}

output "gateway_subnet_id" {
  description = "ID of the Gateway subnet"
  value       = azurerm_subnet.gateway_subnet.id
}

output "apim_subnet_id" {
  description = "ID of the API Management subnet"
  value       = azurerm_subnet.apim_subnet.id
}

output "ase_subnet_id" {
  description = "ID of the App Service Environment subnet"
  value       = azurerm_subnet.ase_subnet.id
}

output "container_subnet_id" {
  description = "ID of the Container App Environment subnet"
  value       = azurerm_subnet.container_subnet.id
}