# Azure Enterprise Application Disaster Recovery
# Terraform Main Configuration

# Configure providers
provider "azurerm" {
  features {}
  # Use appropriate authentication method
}

# Define variables
variable "primary_location" {
  description = "The location of the primary region"
  default     = "eastus"
}

variable "dr_location" {
  description = "The location of the disaster recovery region"
  default     = "westus"
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  default     = "app"
}

variable "environment" {
  description = "Environment name"
  default     = "prod"
}

# Resource groups
resource "azurerm_resource_group" "primary_rg" {
  name     = "${var.resource_prefix}-${var.environment}-${var.primary_location}-rg"
  location = var.primary_location
  
  tags = {
    Environment = var.environment
    DRRole      = "Primary"
  }
}

resource "azurerm_resource_group" "dr_rg" {
  name     = "${var.resource_prefix}-dr-${var.dr_location}-rg"
  location = var.dr_location
  
  tags = {
    Environment = var.environment
    DRRole      = "Secondary"
  }
}

resource "azurerm_resource_group" "global_rg" {
  name     = "${var.resource_prefix}-global-rg"
  location = var.primary_location
  
  tags = {
    Environment = var.environment
    DRRole      = "Global"
  }
}

# Include modules
module "primary_network" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.primary_rg.name
  location            = var.primary_location
  environment         = var.environment
  address_space       = ["10.1.0.0/16"]
  resource_prefix     = var.resource_prefix
  dr_role             = "Primary"
}

module "dr_network" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.dr_rg.name
  location            = var.dr_location
  environment         = var.environment
  address_space       = ["10.2.0.0/16"]
  resource_prefix     = var.resource_prefix
  dr_role             = "Secondary"
}

# VNet Peering
resource "azurerm_virtual_network_peering" "primary_to_dr" {
  name                      = "primary-to-dr"
  resource_group_name       = azurerm_resource_group.primary_rg.name
  virtual_network_name      = module.primary_network.vnet_name
  remote_virtual_network_id = module.dr_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "dr_to_primary" {
  name                      = "dr-to-primary"
  resource_group_name       = azurerm_resource_group.dr_rg.name
  virtual_network_name      = module.dr_network.vnet_name
  remote_virtual_network_id = module.primary_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

# SQL Server and Database with Failover Group
module "primary_sql" {
  source = "./modules/data/sql"
  
  resource_group_name = azurerm_resource_group.primary_rg.name
  location            = var.primary_location
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  dr_role             = "Primary"
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
}

module "dr_sql" {
  source = "./modules/data/sql"
  
  resource_group_name = azurerm_resource_group.dr_rg.name
  location            = var.dr_location
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  dr_role             = "Secondary"
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
}

# SQL Failover Group
resource "azurerm_sql_failover_group" "failover_group" {
  name                = "${var.resource_prefix}-${var.environment}-fg"
  resource_group_name = azurerm_resource_group.primary_rg.name
  server_name         = module.primary_sql.server_name
  databases           = module.primary_sql.database_ids
  
  partner_servers {
    id = module.dr_sql.server_id
  }
  
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
  
  readonly_endpoint_failover_policy {
    mode = "Enabled"
  }
}

# App Service with DR
module "primary_app_service" {
  source = "./modules/compute/app_service"
  
  resource_group_name = azurerm_resource_group.primary_rg.name
  location            = var.primary_location
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  dr_role             = "Primary"
  app_settings        = {
    "WEBSITE_DNS_SERVER": "168.63.129.16",
    "WEBSITE_VNET_ROUTE_ALL": "1"
    # Add application-specific settings
  }
  subnet_id           = module.primary_network.app_service_subnet_id
}

module "dr_app_service" {
  source = "./modules/compute/app_service"
  
  resource_group_name = azurerm_resource_group.dr_rg.name
  location            = var.dr_location
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  dr_role             = "Secondary"
  app_settings        = {
    "WEBSITE_DNS_SERVER": "168.63.129.16",
    "WEBSITE_VNET_ROUTE_ALL": "1"
    # Add application-specific settings
  }
  subnet_id           = module.dr_network.app_service_subnet_id
}

# Traffic Manager for global load balancing
resource "azurerm_traffic_manager_profile" "tm_profile" {
  name                = "${var.resource_prefix}-${var.environment}-tm"
  resource_group_name = azurerm_resource_group.global_rg.name
  
  traffic_routing_method = "Priority"
  
  dns_config {
    relative_name = "${var.resource_prefix}-${var.environment}"
    ttl           = 60
  }
  
  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
  
  tags = {
    Environment = var.environment
    DRRole      = "Global"
  }
}

resource "azurerm_traffic_manager_endpoint" "primary_endpoint" {
  name                = "primary-endpoint"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.tm_profile.name
  type                = "azureEndpoints"
  target_resource_id  = module.primary_app_service.app_service_id
  priority            = 1
  endpoint_status     = "Enabled"
}

resource "azurerm_traffic_manager_endpoint" "dr_endpoint" {
  name                = "dr-endpoint"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.tm_profile.name
  type                = "azureEndpoints"
  target_resource_id  = module.dr_app_service.app_service_id
  priority            = 2
  endpoint_status     = "Enabled"
}

# Monitoring resources
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = azurerm_resource_group.global_rg.name
  location            = var.primary_location
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  primary_app_id      = module.primary_app_service.app_service_id
  dr_app_id           = module.dr_app_service.app_service_id
}

# Outputs
output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.tm_profile.fqdn
}

output "primary_app_url" {
  value = module.primary_app_service.app_service_url
}

output "dr_app_url" {
  value = module.dr_app_service.app_service_url
}

output "primary_sql_server_fqdn" {
  value = module.primary_sql.server_fqdn
}

output "dr_sql_server_fqdn" {
  value = module.dr_sql.server_fqdn
}

output "sql_failover_group_name" {
  value = azurerm_sql_failover_group.failover_group.name
}
