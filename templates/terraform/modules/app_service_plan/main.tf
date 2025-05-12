/**
 * # App Service Plan Module
 * This module creates an Azure App Service Plan that can be used with App Services or Function Apps.
 * Supports both Windows and Linux, and can be deployed in an ASE or as a public service plan.
 */

locals {
  resource_prefix = "asp-${var.environment}-${var.region}"
}

resource "azurerm_service_plan" "main" {
  name                = "${local.resource_prefix}-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.region
  os_type             = var.os_type
  sku_name            = var.sku_name
  app_service_environment_id = var.ase_id # This is already optional (null by default)
  worker_count        = var.worker_count
  
  tags = var.tags
}