/**
 * # App Service Module
 * This module creates an Azure App Service (Web App), supporting both Windows and Linux,
 * and can be deployed in an ASE or as a public service.
 */

locals {
  resource_prefix = "app-${var.environment}-${var.region}"
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  count               = var.os_type == "Linux" ? 1 : 0
  name                = "${local.resource_prefix}-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.region
  service_plan_id     = var.app_service_plan_id

  site_config {
    always_on                = true
    minimum_tls_version     = "1.2"
    application_stack {
      dotnet_version         = var.dotnet_version
      java_version           = var.java_version
      node_version           = var.node_version
      php_version            = var.php_version
      python_version         = var.python_version
    }

    health_check_path       = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
  }

  app_settings = var.app_settings

  identity {
    type = "SystemAssigned"
  }

  https_only = true

  # Only apply VNet integration if subnet ID is provided
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  
  tags = var.tags
}

# Windows Web App
resource "azurerm_windows_web_app" "main" {
  count               = var.os_type == "Windows" ? 1 : 0
  name                = "${local.resource_prefix}-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.region
  service_plan_id     = var.app_service_plan_id

  site_config {
    always_on                = true
    minimum_tls_version     = "1.2"
    application_stack {
      current_stack          = var.current_stack
      dotnet_version         = var.dotnet_version
      java_version           = var.java_version
      node_version           = var.node_version
      php_version            = var.php_version
    }

    health_check_path       = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
  }

  app_settings = var.app_settings

  identity {
    type = "SystemAssigned"
  }

  https_only = true

  # Only apply VNet integration if subnet ID is provided
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  
  tags = var.tags
}