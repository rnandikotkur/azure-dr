#!/usr/bin/env pwsh
# Configure-TerraformBackend.ps1
#
# This script helps configure the Terraform backend for a specific region and resource group.
# It generates the terraform init command with the appropriate backend configuration parameters.

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("ncus", "scus")]
    [string]$Region,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageResourceGroup = "tfstate-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccount = "terraformstate",
    
    [Parameter(Mandatory=$false)]
    [string]$Container = "tfstate"
)

# Generate a sanitized resource group name for the state file key
$StateKey = "$Region/$ResourceGroupName.tfstate"

# Set the environment directory
$EnvironmentPath = "../environments/$Region"

# Check if the environment directory exists
if (-not (Test-Path $EnvironmentPath)) {
    Write-Error "Environment directory not found: $EnvironmentPath"
    exit 1
}

# Change to the environment directory
Set-Location -Path $EnvironmentPath

# Generate and display the terraform init command
$Command = "terraform init -backend-config=""resource_group_name=$StorageResourceGroup"" -backend-config=""storage_account_name=$StorageAccount"" -backend-config=""container_name=$Container"" -backend-config=""key=$StateKey"""

Write-Host "Executing: $Command"
Write-Host ""
Write-Host "This will configure Terraform to use the following backend:"
Write-Host "  - Resource Group: $StorageResourceGroup"
Write-Host "  - Storage Account: $StorageAccount"
Write-Host "  - Container: $Container"
Write-Host "  - State Key: $StateKey"
Write-Host ""

# Ask for confirmation
$Confirm = Read-Host "Do you want to continue? (Y/N)"
if ($Confirm -ne "Y" -and $Confirm -ne "y") {
    Write-Host "Operation cancelled."
    exit 0
}

# Execute the command
Invoke-Expression $Command

Write-Host ""
Write-Host "Backend configuration complete. You can now plan and apply your Terraform configuration:"
Write-Host "  terraform plan -var=""resource_group_name=$ResourceGroupName"" -out=tfplan"
Write-Host "  terraform apply tfplan"
