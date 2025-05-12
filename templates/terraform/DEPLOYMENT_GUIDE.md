# Azure DR Deployment Guide

This document provides detailed instructions on how to use the PowerShell scripts and pipelines in this repository to deploy and manage the Azure DR infrastructure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Small-Scale Deployment](#small-scale-deployment)
- [Large-Scale Production Deployment](#large-scale-production-deployment)
- [DR Testing](#dr-testing)
- [DR Activation](#dr-activation)
- [Cleanup and Decommissioning](#cleanup-and-decommissioning)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before getting started, ensure you have the following tools and permissions:

- **Azure CLI**: Installed and configured
- **Terraform**: Version 1.5.0 or higher
- **PowerShell**: Version 5.1 or higher
- **Azure Permissions**: Contributor role (or higher) on the subscription
- **Azure DevOps**: Access to create and run pipelines (if using CI/CD)

## Initial Setup

Follow these steps to set up the infrastructure for Terraform state management:

### Set Up Terraform State Storage

First, create the Azure Storage infrastructure for Terraform state management:

```powershell
cd scripts
./Setup-TerraformStateStorage.ps1
```

This script will:
- Create a resource group for Terraform state storage
- Create a Storage Account with GRS (geo-redundant storage)
- Create a Blob Container for storing state files
- Display the backend configuration for Terraform

Take note of the output, as you'll need these values for the Terraform backend configuration.

## Small-Scale Deployment

For smaller environments with a limited number of resource groups and compute services, follow this sequence:

### 1. Import Existing Resources (Optional)

If you have existing infrastructure in Azure that you want to manage with Terraform:

```powershell
cd scripts
./Import-ExistingResources.ps1
```

Make sure to edit the script first to set your subscription ID and resource group name.

### 2. Deploy Always-On Infrastructure in Primary Region (North Central US)

#### Step 2.1: Configure Terraform Backend

```powershell
cd scripts
./Configure-TerraformBackend.ps1 -Region ncus -ResourceGroupName main-rg
```

#### Step 2.2: Deploy the Infrastructure

```powershell
cd ../environments/ncus
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Deploy Always-On Infrastructure in DR Region (South Central US)

#### Step 3.1: Configure Terraform Backend

```powershell
cd scripts
./Configure-TerraformBackend.ps1 -Region scus -ResourceGroupName dr-always-on-rg
```

#### Step 3.2: Deploy the Always-On Infrastructure

```powershell
cd ../environments/scus
terraform plan -var="deploy_compute=false" -out=tfplan
terraform apply tfplan
```

## Large-Scale Production Deployment

For large production environments with many resource groups and hundreds of compute services, use the `Sync-DREnvironment.ps1` script which automates the process:

### 1. Analyze Environment and Generate DR Configurations

```powershell
cd scripts
./Sync-DREnvironment.ps1 -SubscriptionId "your-subscription-id"
```

This script will:
- Discover all resource groups in North Central US
- Analyze the compute resources in each resource group
- Generate Terraform configurations for the DR resources
- Create corresponding resource groups in South Central US
- Organize the configurations by resource group

The generated configurations will be in the `./dr-terraform` directory, organized by resource group.

Optional parameters:
- `-ResourceGroupFilter "app-*"`: Filter resource groups by pattern
- `-DRSuffix "dr"`: Customize the suffix for DR resources
- `-SkipExistingResources`: Skip resource groups that already exist in DR region
- `-WhatIf`: Simulation mode without creating resources

### 2. Review and Customize the Generated Configurations

Review the Terraform configurations in the `./dr-terraform` directory and make any necessary adjustments.

### 3. Deploy Always-On Infrastructure for Each Resource Group

For each resource group:

```powershell
cd dr-terraform/<resource-group-name>

# Initialize Terraform with backend configuration
terraform init `
  -backend-config="resource_group_name=tfstate-rg" `
  -backend-config="storage_account_name=<storage-account>" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=scus/<resource-group-name>dr.tfstate"

# Deploy the always-on infrastructure
terraform plan -var="deploy_compute=false" -out=tfplan
terraform apply tfplan
```

### 4. Automate with Azure DevOps Pipelines (Optional)

You can create a pipeline for each resource group or a single pipeline with multiple stages:

```yaml
# Example pipeline structure for multiple resource groups
stages:
- stage: DeployInfrastructureRG1
  jobs:
  - job: Deploy
    steps:
    - script: |
        cd dr-terraform/resource-group-1
        terraform init -backend-config=...
        terraform plan -var="deploy_compute=false" -out=tfplan
        terraform apply tfplan

- stage: DeployInfrastructureRG2
  jobs:
  - job: Deploy
    steps:
    - script: |
        cd dr-terraform/resource-group-2
        terraform init -backend-config=...
        terraform plan -var="deploy_compute=false" -out=tfplan
        terraform apply tfplan

# Additional stages for other resource groups...
```

## DR Testing

It's important to regularly test your DR infrastructure to ensure it works when needed:

### 1. Select Resource Groups for Testing

Choose a subset of resource groups to test:

```powershell
cd dr-terraform/resource-group-1

# Initialize with backend configuration
terraform init -backend-config=...

# Deploy compute resources for testing
terraform plan -var="deploy_compute=true" -out=tfplan
terraform apply tfplan
```

### 2. Test Application Functionality

Test all critical functionality in the deployed DR resources.

### 3. Clean Up After Testing

```powershell
cd dr-terraform/resource-group-1
terraform plan -var="deploy_compute=false" -out=tfplan
terraform apply tfplan
```

This will destroy the on-demand compute resources while keeping the always-on infrastructure.

## DR Activation

During a disaster recovery event, follow these steps to activate the DR region:

### 1. Deploy Compute Resources for All Resource Groups

For each resource group:

```powershell
cd dr-terraform/resource-group-1
terraform plan -var="deploy_compute=true" -out=tfplan
terraform apply tfplan
```

You can automate this with Azure DevOps pipelines for faster activation.

### 2. Redirect Traffic

Update your traffic routing mechanism (Azure Traffic Manager, Front Door, DNS, etc.) to direct traffic to the DR region.

## Cleanup and Decommissioning

### Primary Region Recovery

Once the primary region is operational again:

1. Deploy any updates to the primary region
2. Test functionality in the primary region
3. Redirect traffic back to the primary region
4. Destroy the on-demand compute resources in the DR region:

```powershell
cd dr-terraform/resource-group-1
terraform plan -var="deploy_compute=false" -out=tfplan
terraform apply tfplan
```

## Best Practices

### State Management

- **Separate State Files**: Keep state files separate for different resource groups
- **Regular Backups**: Set up regular backups of your Terraform state
- **Version Control**: Store your Terraform code in version control (e.g., Git)
- **State Locking**: Azure Blob Storage provides state locking to prevent concurrent modifications

### Infrastructure

- **Regular Testing**: Test your DR infrastructure regularly (at least quarterly)
- **Documentation**: Keep documentation up-to-date with any changes
- **Monitoring**: Set up monitoring in both regions to detect failures
- **Alerting**: Configure alerts for any DR-related events

### Resource Group Organization

- **Consistent Naming**: Use consistent naming patterns for resources across regions
- **Tagging**: Tag all resources with source, purpose, and DR-related information
- **Resource Grouping**: Group related resources together for easier management

## Troubleshooting

### Common Issues

#### 1. State Locking Errors

```
Error: Error locking state: Error acquiring the state lock
```

**Solution**: Wait for the lock to be released or use `terraform force-unlock` if necessary.

#### 2. Missing Dependencies

```
Error: Resource depends on non-existent resource
```

**Solution**: Make sure you've deployed the dependencies first (networking, ASE, etc.).

#### 3. Azure Resource Limits

```
Error: Creating resource failed with status: 409
```

**Solution**: Check your Azure subscription limits and request increases if needed.

#### 4. Backend Configuration Errors

```
Error: Failed to get existing workspaces
```

**Solution**: Double-check your backend configuration and make sure the storage account exists.

#### 5. PowerShell Execution Policy

```
Running scripts is disabled on this system
```

**Solution**: Run PowerShell as administrator and set the execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

#### 6. Resource Group Analysis Errors

```
Error: The resource 'resource-group-name' could not be found
```

**Solution**: Make sure the resource group exists and you have permissions to access it.

### Getting Help

If you encounter issues not covered in this guide:

1. Check the Terraform documentation: https://www.terraform.io/docs
2. Check the Azure provider documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
3. Open an issue in the repository
4. Contact the infrastructure team
