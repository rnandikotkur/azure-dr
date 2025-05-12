/**
 * # App Service Environment Module
 * This module creates an Azure App Service Environment v3.
 */

locals {
  resource_prefix = "ase-${var.environment}-${var.region}"
}

resource "azurerm_app_service_environment_v3" "main" {
  name                         = "${local.resource_prefix}"
  resource_group_name          = var.resource_group_name
  subnet_id                    = var.subnet_id
  allow_new_private_endpoint_connections = true
  dedicated_host_count         = var.dedicated_host_count
  zone_redundant               = var.zone_redundant

  cluster_setting {
    name  = "DisableAppServicePerimeterEncryption"
    value = "0"
  }

  cluster_setting {
    name  = "FrontEndSSLCipherSuiteOrder"
    value = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  }

  tags = var.tags
}