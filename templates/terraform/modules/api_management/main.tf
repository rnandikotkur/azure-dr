/**
 * # API Management Module
 * This module creates an Azure API Management service.
 */

locals {
  resource_prefix = "apim-${var.environment}-${var.region}"
}

resource "azurerm_api_management" "main" {
  name                = "${local.resource_prefix}"
  location            = var.region
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  
  virtual_network_type = var.subnet_id != null ? "Internal" : "None"
  
  dynamic "virtual_network_configuration" {
    for_each = var.subnet_id != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}