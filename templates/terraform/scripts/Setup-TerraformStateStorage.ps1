#!/usr/bin/env pwsh
# Setup-TerraformStateStorage.ps1
#
# This script creates the Azure Storage infrastructure needed for Terraform state management.
# It creates a resource group, storage account, and container for Terraform state files.

param(
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "tfstate-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccount = "tfstate$(Get-Random -Minimum 10000 -Maximum 99999)",
    
    [Parameter(Mandatory=$false)]
    [string]$Container = "tfstate"
)

# Validate storage account name
if ($StorageAccount -notmatch '^[a-z0-9]{3,24}$') {
    Write-Error "Storage account name must be 3-24 lowercase alphanumeric characters."
    exit 1
}

Write-Host "This script will create the following Azure resources for Terraform state management:"
Write-Host "  - Resource Group: $ResourceGroup in $Location"
Write-Host "  - Storage Account: $StorageAccount (with GRS)"
Write-Host "  - Container: $Container"
Write-Host ""

# Ask for confirmation
$Confirm = Read-Host "Do you want to continue? (Y/N)"
if ($Confirm -ne "Y" -and $Confirm -ne "y") {
    Write-Host "Operation cancelled."
    exit 0
}

# Check if Azure CLI is installed
try {
    $null = Get-Command az -ErrorAction Stop
} catch {
    Write-Error "Azure CLI not found. Please install it: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login status..."
try {
    $null = az account show
} catch {
    Write-Host "Not logged in to Azure. Please log in:"
    az login
}

# Create resource group
Write-Host "Creating resource group..."
try {
    az group create --name $ResourceGroup --location $Location
} catch {
    Write-Error "Failed to create resource group."
    exit 1
}

# Create storage account
Write-Host "Creating storage account..."
try {
    az storage account create `
        --resource-group $ResourceGroup `
        --name $StorageAccount `
        --sku "Standard_GRS" `
        --encryption-services blob `
        --min-tls-version "TLS1_2" `
        --allow-blob-public-access false
} catch {
    Write-Error "Failed to create storage account."
    exit 1
}

# Get storage account key
Write-Host "Getting storage account key..."
try {
    $AccountKey = az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query "[0].value" -o tsv
} catch {
    Write-Error "Failed to get storage account key."
    exit 1
}

# Create blob container
Write-Host "Creating blob container..."
try {
    az storage container create `
        --name $Container `
        --account-name $StorageAccount `
        --account-key $AccountKey
} catch {
    Write-Error "Failed to create blob container."
    exit 1
}

Write-Host ""
Write-Host "Terraform state storage has been successfully set up."
Write-Host ""
Write-Host "Use the following backend configuration in your Terraform code:"
Write-Host ""
Write-Host "terraform {"
Write-Host "  backend ""azurerm"" {"
Write-Host "    resource_group_name  = ""$ResourceGroup"""
Write-Host "    storage_account_name = ""$StorageAccount"""
Write-Host "    container_name       = ""$Container"""
Write-Host "    key                  = ""<your-state-file-name>.tfstate"""
Write-Host "  }"
Write-Host "}"
Write-Host ""
Write-Host "Or use our helper script to initialize Terraform with these settings:"
Write-Host "./Configure-TerraformBackend.ps1 -Region <region> -ResourceGroupName <resource_group_name> \"
Write-Host "  -StorageResourceGroup ""$ResourceGroup"" -StorageAccount ""$StorageAccount"" -Container ""$Container"""
