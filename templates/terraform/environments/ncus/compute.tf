/**
 * # Compute Resources (North Central US)
 * These resources are the compute components in the primary region.
 */

# App Service Plans - Linux in ASE
module "app_service_plan_linux_ase" {
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "linux-ase"
  os_type             = "Linux"
  ase_id              = module.app_service_environment.id
  tags                = var.tags
}

# App Service Plans - Windows in ASE
module "app_service_plan_windows_ase" {
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "windows-ase"
  os_type             = "Windows"
  ase_id              = module.app_service_environment.id
  tags                = var.tags
}

# App Service Plans - Linux Public
module "app_service_plan_linux_public" {
  source              = "../../modules/app_service_plan"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = "linux-public"
  os_type             = "Linux"
  # No ASE ID for public service plans
  tags                = var.tags
}

# App Service Plans - Windows Public
module "app_service_plan_windows_public" {
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

# Linux App Services in ASE
module "app_service_linux_ase" {
  for_each            = toset(["api", "web"])
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Linux"
  app_service_plan_id = module.app_service_plan_linux_ase.id
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Windows App Services in ASE
module "app_service_windows_ase" {
  for_each            = toset(["admin"])
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Windows"
  app_service_plan_id = module.app_service_plan_windows_ase.id
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# App Services - Public

# Linux App Services with public endpoint
module "app_service_linux_public" {
  for_each            = toset(["public-api"])
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Linux"
  app_service_plan_id = module.app_service_plan_linux_public.id
  # No VNet integration for public apps
  tags                = var.tags
}

# Windows App Services with public endpoint
module "app_service_windows_public" {
  for_each            = toset(["public-web"])
  source              = "../../modules/app_service"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  os_type             = "Windows"
  app_service_plan_id = module.app_service_plan_windows_public.id
  # No VNet integration for public apps
  tags                = var.tags
}

# Function Apps - ASE-hosted

# Linux Function Apps in ASE
module "function_app_linux_ase" {
  for_each            = toset(["events"])
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_linux_ase.id
  os_type             = "Linux"
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Windows Function Apps in ASE
module "function_app_windows_ase" {
  for_each            = toset(["processing"])
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_windows_ase.id
  os_type             = "Windows"
  app_settings = {
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
  }
  vnet_integration_subnet_id = module.networking.ase_subnet_id
  tags                = var.tags
}

# Function Apps - Public

# Linux Function Apps with public endpoint
module "function_app_linux_public" {
  for_each            = toset(["webhooks"])
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_linux_public.id
  os_type             = "Linux"
  # No VNet integration for public function apps
  tags                = var.tags
}

# Windows Function Apps with public endpoint
module "function_app_windows_public" {
  for_each            = toset(["integration"])
  source              = "../../modules/function_app"
  region              = var.region
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  name                = each.key
  app_service_plan_id = module.app_service_plan_windows_public.id
  os_type             = "Windows"
  # No VNet integration for public function apps
  tags                = var.tags
}

# Container Apps
module "container_app" {
  for_each                    = toset(["app1", "app2", "app3"])
  source                      = "../../modules/container_app"
  region                      = var.region
  environment                 = var.environment
  resource_group_name         = azurerm_resource_group.main.name
  name                        = each.key
  container_app_environment_id = module.container_app_environment.id
  tags                        = var.tags
}