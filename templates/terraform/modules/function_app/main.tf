/**
 * # Function App Module
 * This module creates an Azure Function App, supporting both Windows and Linux platforms,
 * and can be deployed in an ASE or as a publicly hosted service.
 */

locals {
  resource_prefix = "func-${var.environment}-${var.region}"
}

resource "azurerm_storage_account" "main" {
  name                     = lower(replace("${local.resource_prefix}${var.name}", "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  tags = var.tags
}

# Linux Function App
resource "azurerm_linux_function_app" "main" {
  count                     = var.os_type == "Linux" ? 1 : 0
  name                      = "${local.resource_prefix}-${var.name}"
  resource_group_name       = var.resource_group_name
  location                  = var.region
  service_plan_id           = var.app_service_plan_id
  storage_account_name      = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    always_on                = true
    minimum_tls_version     = "1.2"
    application_stack {
      dotnet_version         = var.dotnet_version
      java_version           = var.java_version
      node_version           = var.node_version
      python_version         = var.python_version
    }

    health_check_path       = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
  }

  app_settings = merge({
    "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }, var.app_settings)

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

# Windows Function App
resource "azurerm_windows_function_app" "main" {
  count                     = var.os_type == "Windows" ? 1 : 0
  name                      = "${local.resource_prefix}-${var.name}"
  resource_group_name       = var.resource_group_name
  location                  = var.region
  service_plan_id           = var.app_service_plan_id
  storage_account_name      = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    always_on                = true
    minimum_tls_version     = "1.2"
    application_stack {
      dotnet_version         = var.dotnet_version
      java_version           = var.java_version
      node_version           = var.node_version
    }

    health_check_path       = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
  }

  app_settings = merge({
    "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }, var.app_settings)

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