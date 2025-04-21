
# Export-ResourceInventory.ps1
# This script exports all Azure resources to a structured Excel spreadsheet for documentation

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$PSScriptRoot\output",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSharedResources
)

# Connect to Azure if not already connected
try {
    Get-AzContext -ErrorAction Stop
} catch {
    Connect-AzAccount
}

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force
}

Write-Host "Exporting comprehensive Azure resource inventory..."

# Query all compute resources
$computeQuery = @"
Resources
| where type in~ ('Microsoft.Web/sites', 'Microsoft.Web/hostingEnvironments', 
                 'Microsoft.App/containerApps', 'Microsoft.App/managedEnvironments')
| extend Team = tostring(tags.Team)
| extend Environment = tostring(tags.Environment)
| extend CustomDomain = tostring(tags.CustomDomain)
| extend AccessType = tostring(tags.AccessType)
| extend ServiceName = tostring(tags.ServiceName)
| extend VNet = case(
    type =~ 'Microsoft.Web/hostingEnvironments', tostring(properties.virtualNetwork.id),
    type =~ 'Microsoft.App/managedEnvironments', tostring(properties.vnetConfiguration.infrastructureSubnetId),
    type =~ 'Microsoft.Web/sites' and properties.hostingEnvironmentProfile.id != "", "In ASE",
    "Public")
| project name, type, resourceGroup, location, subscriptionId, Team, Environment, CustomDomain, AccessType, ServiceName, VNet, tags
"@

$computeResources = Search-AzGraph -Query $computeQuery

# Query all network resources
$networkQuery = @"
Resources
| where type in~ ('Microsoft.Network/virtualNetworks', 'Microsoft.Network/applicationGateways', 
                 'Microsoft.Network/loadBalancers', 'Microsoft.Network/privateEndpoints')
| extend Team = tostring(tags.Team)
| extend Purpose = tostring(tags.Purpose)
| project name, type, resourceGroup, location, subscriptionId, Team, Purpose, properties, tags
"@

$networkResources = Search-AzGraph -Query $networkQuery

# Query all database resources
$databaseQuery = @"
Resources
| where type in~ ('Microsoft.Sql/servers/databases', 'Microsoft.DocumentDB/databaseAccounts', 
                 'Microsoft.DBforMySQL/servers', 'Microsoft.Cache/Redis')
| extend Team = tostring(tags.Team)
| extend Environment = tostring(tags.Environment)
| extend ServiceName = tostring(tags.ServiceName)
| project name, type, resourceGroup, location, subscriptionId, Team, Environment, ServiceName, properties, tags
"@

$databaseResources = Search-AzGraph -Query $databaseQuery

# Try to import the ImportExcel module
$excelModuleAvailable = $false
try {
    Import-Module ImportExcel -ErrorAction Stop
    $excelModuleAvailable = $true
    Write-Host "ImportExcel module found, will export to Excel format"
} catch {
    Write-Host "ImportExcel module not found, will export to CSV format instead"
    Write-Host "To use Excel format, run: Install-Module ImportExcel -Scope CurrentUser"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if ($excelModuleAvailable) {
    # Export to Excel with multiple tabs
    $excelPath = "$OutputPath\azure-resource-inventory-$timestamp.xlsx"
    
    # Tab 1: All Compute Services
    $computeResources | 
        Select-Object name, type, resourceGroup, location, Team, Environment, CustomDomain, AccessType, ServiceName |
        Export-Excel -Path $excelPath -WorksheetName "Compute Services" -AutoSize
    
    # Tab 2: App Service Environments
    $ases = $computeResources | Where-Object { $_.type -eq "microsoft.web/hostingenvironments" }
    if ($ases.Count -gt 0) {
        $ases | 
            Select-Object name, resourceGroup, location, Team |
            Export-Excel -Path $excelPath -WorksheetName "ASEs" -AutoSize
    }
    
    # Tab 3: Container App Environments
    $caes = $computeResources | Where-Object { $_.type -eq "microsoft.app/managedenvironments" }
    if ($caes.Count -gt 0) {
        $caes | 
            Select-Object name, resourceGroup, location, Team |
            Export-Excel -Path $excelPath -WorksheetName "Container App Envs" -AutoSize
    }
    
    # Tab 4: Web & Function Apps
    $apps = $computeResources | Where-Object { $_.type -eq "microsoft.web/sites" }
    if ($apps.Count -gt 0) {
        $apps | 
            Select-Object name, resourceGroup, location, Team, Environment, CustomDomain, AccessType, ServiceName |
            Export-Excel -Path $excelPath -WorksheetName "Web & Function Apps" -AutoSize
    }
    
    # Tab 5: Container Apps
    $containerApps = $computeResources | Where-Object { $_.type -eq "microsoft.app/containerapps" }
    if ($containerApps.Count -gt 0) {
        $containerApps | 
            Select-Object name, resourceGroup, location, Team, Environment, CustomDomain, AccessType, ServiceName |
            Export-Excel -Path $excelPath -WorksheetName "Container Apps" -AutoSize
    }
    
    # Tab 6: VNets
    $vnets = $networkResources | Where-Object { $_.type -eq "microsoft.network/virtualnetworks" }
    if ($vnets.Count -gt 0) {
        $vnets | 
            Select-Object name, resourceGroup, location, Team, Purpose |
            Export-Excel -Path $excelPath -WorksheetName "VNets" -AutoSize
    }
    
    # Tab 7: Databases
    if ($databaseResources.Count -gt 0) {
        $databaseResources | 
            Select-Object name, type, resourceGroup, location, Team, Environment, ServiceName |
            Export-Excel -Path $excelPath -WorksheetName "Databases" -AutoSize
    }
    
    Write-Host "Resource inventory exported to Excel: $excelPath"
} else {
    # Export to CSV files
    $computeResources | 
        Select-Object name, type, resourceGroup, location, Team, Environment, CustomDomain, AccessType, ServiceName |
        Export-Csv -Path "$OutputPath\compute-resources-$timestamp.csv" -NoTypeInformation
    
    $networkResources | 
        Select-Object name, type, resourceGroup, location, Team, Purpose |
        Export-Csv -Path "$OutputPath\network-resources-$timestamp.csv" -NoTypeInformation
    
    $databaseResources | 
        Select-Object name, type, resourceGroup, location, Team, Environment, ServiceName |
        Export-Csv -Path "$OutputPath\database-resources-$timestamp.csv" -NoTypeInformation
        
    Write-Host "Resource inventory exported to CSV files in: $OutputPath"
}

# Export to JSON for further processing
$allResources = @{
    ComputeResources = $computeResources
    NetworkResources = $networkResources
    DatabaseResources = $databaseResources
    ExportTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$allResources | ConvertTo-Json -Depth 10 > "$OutputPath\azure-resources-$timestamp.json"
Write-Host "Complete resource JSON data exported to: $OutputPath\azure-resources-$timestamp.json"
