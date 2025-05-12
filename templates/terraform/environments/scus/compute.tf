/**
 * # Compute Resources (South Central US - DR Region)
 * These resources are the on-demand compute components, only deployed during DR events.
 */

# App Service Plans - conditionally deployed based on deploy_compute flag

# Linux App Service Plan in ASE - conditionally deployed
module "app_service_plan_linux_ase" {
  count               = var.deploy_compute ? 1 : 0
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "linux-ase"
  os_type             = "Linux"
  ase_id              = module.app_service_environment.id
  tags                = var.tags
}

# Windows App Service Plan in ASE - conditionally deployed
module "app_service_plan_windows_ase" {
  count               = var.deploy_compute ? 1 : 0
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "windows-ase"
  os_type             = "Windows"
  ase_id              = module.app_service_environment.id
  tags                = var.tags
}

# Linux App Service Plan with public endpoint - conditionally deployed
module "app_service_plan_linux_public" {
  count               = var.deploy_compute ? 1 : 0
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "linux-public"
  os_type             = "Linux"
  # No ASE ID for public service plans
  tags                = var.tags
}

# Windows App Service Plan with public endpoint - conditionally deployed
module "app_service_plan_windows_public" {
  count               = var.deploy_compute ? 1 : 0
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "windows-public"
  os_type             = "Windows"
  # No ASE ID for public service plans
  tags                = var.tags
}

# App Services - ASE-hosted

# Linux App Services in ASE - conditionally deployed
module "app_service_linux_ase" {
  for_each            = var.deploy_compute ? toset(["api", "web"]) : []
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Linux"
  app_service_plan_id = module.app_service_plan_linux_ase[0].id
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
    "DISASTER_RECOVERY_MODE" = "true"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Windows App Services in ASE - conditionally deployed
module "app_service_windows_ase" {
  for_each            = var.deploy_compute ? toset(["admin"]) : []
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Windows"
  app_service_plan_id = module.app_service_plan_windows_ase[0].id
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
    "DISASTER_RECOVERY_MODE" = "true"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# App Services - Public

# Linux App Services with public endpoint - conditionally deployed
module "app_service_linux_public" {
  for_each            = var.deploy_compute ? toset(["public-api"]) : []
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Linux"
  app_service_plan_id = module.app_service_plan_linux_public[0].id
  app_settings = {
    "DISASTER_RECOVERY_MODE" = "true"
  }
  # No VNet integration for public apps
  tags                = var.tags
}

# Windows App Services with public endpoint - conditionally deployed
module "app_service_windows_public" {
  for_each            = var.deploy_compute ? toset(["public-web"]) : []
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Windows"
  app_service_plan_id = module.app_service_plan_windows_public[0].id
  app_settings = {
    "DISASTER_RECOVERY_MODE" = "true"
  }
  # No VNet integration for public apps
  tags                = var.tags
}

# Function Apps - ASE-hosted

# Linux Function Apps in ASE - conditionally deployed
module "function_app_linux_ase" {
  for_each            = var.deploy_compute ? toset(["events"]) : []
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_linux_ase[0].id
  os_type             = "Linux"
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
    "DISASTER_RECOVERY_MODE" = "true"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Windows Function Apps in ASE - conditionally deployed
module "function_app_windows_ase" {
  for_each            = var.deploy_compute ? toset(["processing"]) : []
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_windows_ase[0].id
  os_type             = "Windows"
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
    "DISASTER_RECOVERY_MODE" = "true"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Function Apps - Public

# Linux Function Apps with public endpoint - conditionally deployed
module "function_app_linux_public" {
  for_each            = var.deploy_compute ? toset(["webhooks"]) : []
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_linux_public[0].id
  os_type             = "Linux"
  app_settings = {
    "DISASTER_RECOVERY_MODE" = "true"
  }
  # No VNet integration for public function apps
  tags                = var.tags
}

# Windows Function Apps with public endpoint - conditionally deployed
module "function_app_windows_public" {
  for_each            = var.deploy_compute ? toset(["integration"]) : []
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_windows_public[0].id
  os_type             = "Windows"
  app_settings = {
    "DISASTER_RECOVERY_MODE" = "true"
  }
  # No VNet integration for public function apps
  tags                = var.tags
}

# Container Apps - conditionally deployed
module "container_app" {
  for_each                    = var.deploy_compute ? toset(["app1", "app2", "app3"]) : []
  source                      = "../../modules/container_app"
  region                      = var.region
  environment                 = var.environment
  resource_group_name         = azurerm_resource_group.main.name
  name                        = each.key
  container_app_environment_id = module.container_app_environment.id
  environment_variables = {
    "DISASTER_RECOVERY_MODE" = "true"
  }
  tags                        = var.tags
}