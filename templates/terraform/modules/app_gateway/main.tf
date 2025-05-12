/**
 * # Application Gateway Module
 * This module creates an Azure Application Gateway with WAF capabilities.
 */

locals {
  resource_prefix = "appgw-${var.environment}-${var.region}"
}

resource "azurerm_public_ip" "main" {
  name                = "${local.resource_prefix}-pip"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.tags
}

resource "azurerm_application_gateway" "main" {
  name                = "${local.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.region

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  // Default backend address pool
  backend_address_pool {
    name = "defaultPool"
  }

  // Default backend HTTP settings
  backend_http_settings {
    name                  = "defaultHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  // Default HTTP listener
  http_listener {
    name                           = "defaultListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  // Default routing rule
  request_routing_rule {
    name                       = "defaultRule"
    rule_type                  = "Basic"
    http_listener_name         = "defaultListener"
    backend_address_pool_name  = "defaultPool"
    backend_http_settings_name = "defaultHttpSettings"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  // WAF Policy attachment
  firewall_policy_id = var.waf_policy_id

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      url_path_map,
      probe
    ]
  }
}