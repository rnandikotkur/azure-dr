/**
 * # South Central US Environment (DR Region)
 * This is the main configuration for the South Central US DR region.
 */

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}-${var.region_short}"
  location = var.region
  tags     = var.tags
}