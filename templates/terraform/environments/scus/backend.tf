/**
 * # Terraform State Backend Configuration
 * 
 * This file configures the Azure Storage backend for Terraform state management.
 * The actual configuration parameters are NOT hardcoded in this file but provided
 * at runtime using the -backend-config flag with terraform init.
 * 
 * ## Usage Example
 * 
 * ```bash
 * terraform init \
 *   -backend-config="resource_group_name=tfstate-rg" \
 *   -backend-config="storage_account_name=mytfstate1234" \
 *   -backend-config="container_name=tfstate" \
 *   -backend-config="key=scus/resource-group-name.tfstate"
 * ```
 * 
 * ## State Separation Strategy
 * 
 * We're using a per-resource-group state file strategy. This means:
 * - Each resource group has its own state file
 * - State files are organized hierarchically by region and resource group
 * - The key naming convention is: <region>/<resource-group-name>.tfstate
 * 
 * This approach allows for:
 * - Independent management of resource groups
 * - Reduced blast radius for state changes
 * - Parallel operations on different resource groups
 * - Better state locking granularity
 */

terraform {
  backend "azurerm" {
    # Backend configuration will be provided via -backend-config parameters
  }
}
