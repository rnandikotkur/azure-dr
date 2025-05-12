/**
 * # Container App Environment Module
 * This module creates an Azure Container App Environment.
 */

locals {
  resource_prefix = "cae-${var.environment}-${var.region}"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.resource_prefix}-logs"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${local.resource_prefix}"
  location                   = var.region
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  infrastructure_subnet_id   = var.subnet_id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled     = var.zone_redundancy_enabled
  
  tags = var.tags
}