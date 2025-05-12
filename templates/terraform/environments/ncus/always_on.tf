/**
 * # Always-On Infrastructure (North Central US)
 * These resources are always running in the primary region.
 */

# WAF Policy
resource "azurerm_web_application_firewall_policy" "main" {
  name                = "wafpolicy-${var.environment}-${var.region_short}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

# Networking
module "networking" {
  source              = "../../modules/networking"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  existing_vnet_id    = var.existing_vnet_id
  tags                = var.tags
}

# App Service Environment
module "app_service_environment" {
  source              = "../../modules/app_service_environment"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.ase_subnet_id
  tags                = var.tags
}

# Container App Environment
module "container_app_environment" {
  source              = "../../modules/container_app_environment"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.container_subnet_id
  tags                = var.tags
}

# Application Gateway
module "app_gateway" {
  source              = "../../modules/app_gateway"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.gateway_subnet_id
  waf_policy_id       = azurerm_web_application_firewall_policy.main.id
  tags                = var.tags
}

# API Management
module "api_management" {
  source              = "../../modules/api_management"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.apim_subnet_id
  tags                = var.tags
}