/**
 * # Networking Module
 * This module handles networking configuration for the Azure infrastructure.
 * It supports working with existing VNets and creating subnets as needed.
 */

locals {
  resource_prefix = "net-${var.environment}-${var.region}"
}

// Reference existing VNet if provided
data "azurerm_virtual_network" "existing" {
  count               = var.existing_vnet_id != "" ? 1 : 0
  name                = element(split("/", var.existing_vnet_id), length(split("/", var.existing_vnet_id)) - 1)
  resource_group_name = var.resource_group_name
}

// Create new VNet if not using existing
resource "azurerm_virtual_network" "main" {
  count               = var.existing_vnet_id == "" ? 1 : 0
  name                = "${local.resource_prefix}-vnet"
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  
  tags = var.tags
}

// Create subnets in the VNet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "gateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.existing_vnet_id != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
  address_prefixes     = [var.gateway_subnet_cidr]
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = "apim-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.existing_vnet_id != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
  address_prefixes     = [var.apim_subnet_cidr]
}

resource "azurerm_subnet" "ase_subnet" {
  name                 = "ase-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.existing_vnet_id != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
  address_prefixes     = [var.ase_subnet_cidr]
  delegation {
    name = "ase-delegation"
    service_delegation {
      name    = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "container_subnet" {
  name                 = "container-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.existing_vnet_id != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
  address_prefixes     = [var.container_subnet_cidr]
  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}