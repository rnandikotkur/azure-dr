# Azure Enterprise Application Disaster Recovery
# Networking Module

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "dr_role" {
  description = "Role in DR strategy (Primary or Secondary)"
  type        = string
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

# Subnets
resource "azurerm_subnet" "app_service_subnet" {
  name                 = "AppServiceSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 0)]
  
  delegation {
    name = "app-service-delegation"
    
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "ase_subnet" {
  name                 = "ASESubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 1)]
}

resource "azurerm_subnet" "container_apps_subnet" {
  name                 = "ContainerAppsSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 2)]
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "AppGatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 3)]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"  # This name is required by Azure
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 4)]
}

# Network Security Groups
resource "azurerm_network_security_group" "app_service_nsg" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "app_service_nsg_association" {
  subnet_id                 = azurerm_subnet.app_service_subnet.id
  network_security_group_id = azurerm_network_security_group.app_service_nsg.id
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "private_dns" {
  name                = "${var.resource_prefix}.${var.environment}.local"
  resource_group_name = var.resource_group_name
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "${var.resource_prefix}-${var.environment}-${var.dr_role}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# Application Gateway
resource "azurerm_public_ip" "app_gateway_pip" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-agw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }
  
  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }
  
  frontend_port {
    name = "https-port"
    port = 443
  }
  
  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.app_gateway_pip.id
  }
  
  # Basic placeholder configuration - would be customized for actual applications
  backend_address_pool {
    name = "default-backend-pool"
  }
  
  backend_http_settings {
    name                  = "https-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    probe_name            = "health-probe"
  }
  
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    # ssl_certificate_name         = "ssl-cert" # Would be configured in actual implementation
  }
  
  probe {
    name                = "health-probe"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Https"
    path                = "/health"
  }
  
  # Basic rule - would be customized for actual applications
  request_routing_rule {
    name                       = "default-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "https-settings"
    priority                   = 100
  }
  
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
  
  # In a real implementation, you'd add:
  # - SSL certificates
  # - Custom WAF rules
  # - Path-based routing rules
  # - Application-specific backend pools
  # - Custom probes for different services
}

# Azure Firewall
resource "azurerm_public_ip" "firewall_pip" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.resource_prefix}-${var.environment}-${var.dr_role}-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
  
  tags = {
    Environment = var.environment
    DRRole      = var.dr_role
  }
}

# Firewall Network Rules
resource "azurerm_firewall_network_rule_collection" "basic_network_rules" {
  name                = "basic-network-rules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"
  
  rule {
    name                  = "AllowOutboundDNS"
    source_addresses      = [var.address_space[0]]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["UDP"]
  }
  
  rule {
    name                  = "AllowOutboundHTTPS"
    source_addresses      = [var.address_space[0]]
    destination_ports     = ["443"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}

# Outputs
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "app_service_subnet_id" {
  value = azurerm_subnet.app_service_subnet.id
}

output "ase_subnet_id" {
  value = azurerm_subnet.ase_subnet.id
}

output "container_apps_subnet_id" {
  value = azurerm_subnet.container_apps_subnet.id
}

output "app_gateway_public_ip" {
  value = azurerm_public_ip.app_gateway_pip.ip_address
}

output "app_gateway_id" {
  value = azurerm_application_gateway.app_gateway.id
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.private_dns.id
}

output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.private_dns.name
}
