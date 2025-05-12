# Azure DR Infrastructure with Terraform

This repository contains Terraform code to implement a 1:1 disaster recovery (DR) solution in Azure, with a primary region in North Central US and a DR region in South Central US.

## Architecture Overview

### Primary Region (North Central US)
- VNets with multiple subnets
- Application Gateway with WAF policy
- App Service Environment (ASE)
- Container App Environment
- API Management
- App Services and Function Apps (both in ASE and with public endpoints)
- Container Apps

### DR Region (South Central US)
- Always-on infrastructure: VNets, App Gateway, ASE, Container App Environment, API Management
- On-demand compute resources: App Services, Function Apps, Container Apps

## Directory Structure

```
├── modules/               # Reusable Terraform modules
│   ├── networking/        # VNet and subnet configuration
│   ├── app_gateway/       # Application Gateway with WAF
│   ├── api_management/    # API Management service
│   ├── app_service_environment/ # App Service Environment
│   ├── app_service_plan/  # App Service Plans
│   ├── app_service/       # App Services (Web Apps)
│   ├── function_app/      # Function Apps
│   ├── container_app_environment/ # Container App Environment
│   ├── container_app/     # Container Apps
├── environments/          # Environment-specific configurations
│   ├── ncus/              # North Central US (Primary)
│   │   ├── always_on.tf   # Always-on infrastructure
│   │   ├── compute.tf     # Compute resources
│   │   ├── variables.tf   # Variables for the environment
│   │   ├── main.tf        # Main configuration
│   │   ├── backend.tf     # Terraform state backend configuration
│   ├── scus/              # South Central US (DR)
│   │   ├── always_on.tf   # Always-on DR infrastructure
│   │   ├── compute.tf     # On-demand DR compute resources
│   │   ├── variables.tf   # Variables for the environment
│   │   ├── main.tf        # Main configuration
│   │   ├── backend.tf     # Terraform state backend configuration
├── pipelines/             # CI/CD pipeline configurations
│   ├── ncus_pipeline.yml  # Primary region pipeline
│   ├── scus_always_on_pipeline.yml # DR always-on infrastructure pipeline
│   ├── dr_activation_pipeline.yml # DR activation pipeline
├── scripts/               # Utility scripts
│   ├── Import-ExistingResources.ps1 # PowerShell script to import existing resources
│   ├── Setup-TerraformStateStorage.ps1 # PowerShell script to create state storage
│   ├── Configure-TerraformBackend.ps1 # PowerShell script to configure backend
│   ├── Sync-DREnvironment.ps1 # PowerShell script to sync DR environment
```

## Large-Scale Production Deployment

For large-scale production environments with multiple resource groups and hundreds of compute services, use the `Sync-DREnvironment.ps1` script which:

1. Discovers all resource groups in North Central US
2. Creates matching resource groups in South Central US with a "dr" suffix
3. Analyzes compute resources (App Service Plans, Web Apps, Function Apps, Container Apps)
4. Generates Terraform configurations for each resource group
5. Configures corresponding DR resources with proper naming and tagging

### Running the DR Sync Script

```powershell
cd scripts
./Sync-DREnvironment.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupFilter "app-*"
```

Parameters:
- `SubscriptionId`: Azure subscription ID (optional)
- `PrimaryRegion`: Primary region (default: northcentralus)
- `DRRegion`: DR region (default: southcentralus)
- `DRSuffix`: Suffix for DR resources (default: dr)
- `ResourceGroupFilter`: Filter pattern for resource groups (default: *)
- `SkipExistingResources`: Skip resource groups that already exist in DR region
- `WhatIf`: Run in simulation mode without creating resources

The script generates Terraform configurations in a `./dr-terraform` directory, organized by resource group.

## Terraform State Management

This project implements a state management strategy that:

1. Uses Azure Storage for remote state
2. Separates state files by resource group
3. Organizes state files hierarchically by region and resource group
4. Implements state locking for team environments

### Setting Up State Storage

Before you can use Terraform, you need to set up the state storage:

```powershell
cd scripts
./Setup-TerraformStateStorage.ps1
```

This will create:
- A resource group for Terraform state
- A storage account with GRS (geo-redundant storage)
- A blob container for the state files

### Configuring Terraform Backend

For each environment and resource group, configure the Terraform backend:

```powershell
cd scripts
./Configure-TerraformBackend.ps1 -Region ncus -ResourceGroupName main-rg
```

This will initialize Terraform with the correct backend configuration for the specified region and resource group.

## Getting Started

### Prerequisites
- Azure CLI installed and configured
- Terraform 1.5.0 or higher
- PowerShell for running the helper scripts
- Azure DevOps or GitHub Actions for running pipelines (optional)

### Setup Instructions

1. **Set Up Terraform State Storage**
   ```powershell
   cd scripts
   ./Setup-TerraformStateStorage.ps1
   ```

2. **Generate DR Environment Configurations**
   ```powershell
   cd scripts
   ./Sync-DREnvironment.ps1
   ```

3. **Review and Customize the Generated Configurations**
   Review the generated Terraform configurations in the `./dr-terraform` directory.

4. **Initialize and Apply Terraform for Each Resource Group**
   For each resource group configuration:
   ```powershell
   cd dr-terraform/<resource-group-name>
   terraform init -backend-config="resource_group_name=tfstate-rg" -backend-config="storage_account_name=<storage-account>" -backend-config="container_name=tfstate" -backend-config="key=scus/<resource-group-name>dr.tfstate"
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## DR Activation

During a DR event, activate the compute resources for all resource groups:

```powershell
# For each DR resource group
cd dr-terraform/<resource-group-name>
terraform plan -var="deploy_compute=true" -out=tfplan
terraform apply tfplan
```

Alternatively, you can use Azure DevOps pipelines to automate this process across all resource groups.

## DR Testing

It's recommended to regularly test the DR capability by:

1. Deploying the on-demand compute resources to the DR region for selected resource groups
2. Testing connectivity and functionality
3. Destroying the on-demand compute resources to save costs

## Notes

- Database DR is handled separately as SQL databases are configured with availability groups and continuous replication.
- Traffic management (switching between primary and DR regions) should be configured according to your requirements, typically using Azure Traffic Manager or Azure Front Door.
- The Terraform state is stored in Azure Storage with a per-resource-group separation strategy.
