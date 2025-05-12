/**
 * # Container App Module
 * This module creates an Azure Container App.
 */

locals {
  resource_prefix = "containerapp-${var.environment}-${var.region}"
}

resource "azurerm_container_app" "main" {
  name                         = "${local.resource_prefix}-${var.name}"
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = var.name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    external_enabled = var.external_ingress_enabled
    target_port      = var.target_port
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}