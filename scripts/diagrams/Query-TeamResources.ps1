
# Query-TeamResources.ps1
# This script uses Azure Resource Graph to query resources for a specific team
# and exports them to a JSON file for diagram generation

param(
    [Parameter(Mandatory=$true)]
    [string]$TeamName
)

# Connect to Azure if not already connected
try {
    Get-AzContext -ErrorAction Stop
} catch {
    Connect-AzAccount
}

Write-Host "Querying resources for Team: $TeamName"

# Query Virtual Networks for the team
$vnetQuery = @"
Resources
| where type =~ 'Microsoft.Network/virtualNetworks'
| where tags.Team =~ '$TeamName'
| project name, id, location, resourceGroup, properties, tags
"@

$vnets = Search-AzGraph -Query $vnetQuery

Write-Host "Found $($vnets.Count) Virtual Networks"

# Query ASEs for the team
$aseQuery = @"
Resources
| where type =~ 'Microsoft.Web/hostingEnvironments'
| where tags.Team =~ '$TeamName'
| project name, id, location, resourceGroup, properties, tags
"@

$ases = Search-AzGraph -Query $aseQuery

Write-Host "Found $($ases.Count) App Service Environments"

# Query Container App Environments for the team
$caeQuery = @"
Resources
| where type =~ 'Microsoft.App/managedEnvironments'
| where tags.Team =~ '$TeamName'
| project name, id, location, resourceGroup, properties, tags
"@

$caes = Search-AzGraph -Query $caeQuery

Write-Host "Found $($caes.Count) Container App Environments"

# Query Web Apps in ASE
$webAppsQuery = @"
Resources
| where type =~ 'Microsoft.Web/sites'
| where tags.Team =~ '$TeamName'
| extend hostingEnvId = tostring(properties.hostingEnvironmentProfile.id)
| project name, id, location, resourceGroup, properties, tags, kind = properties.kind, hostingEnvId
"@

$webApps = Search-AzGraph -Query $webAppsQuery

Write-Host "Found $($webApps.Count) Web/Function Apps"

# Query Container Apps
$containerAppsQuery = @"
Resources
| where type =~ 'Microsoft.App/containerApps'
| where tags.Team =~ '$TeamName'
| extend envId = tostring(properties.managedEnvironmentId)
| project name, id, location, resourceGroup, properties, tags, envId
"@

$containerApps = Search-AzGraph -Query $containerAppsQuery

Write-Host "Found $($containerApps.Count) Container Apps"

# Query App Gateway
$appGwQuery = @"
Resources
| where type =~ 'Microsoft.Network/applicationGateways'
| where tags.Team =~ '$TeamName' or tags.Team =~ 'Shared'
| project name, id, location, resourceGroup, properties, tags
"@

$appGateways = Search-AzGraph -Query $appGwQuery

Write-Host "Found $($appGateways.Count) Application Gateways"

# Query Databases (SQL, Cosmos DB, MySQL, Redis)
$databasesQuery = @"
Resources
| where type in~ ('Microsoft.Sql/servers/databases', 'Microsoft.DocumentDB/databaseAccounts', 'Microsoft.DBforMySQL/servers', 'Microsoft.Cache/Redis')
| where tags.Team =~ '$TeamName'
| project name, id, type, location, resourceGroup, properties, tags
"@

$databases = Search-AzGraph -Query $databasesQuery

Write-Host "Found $($databases.Count) Database Resources"

# Export the data to JSON for diagram generation
$teamResources = @{
    TeamName = $TeamName
    VirtualNetworks = $vnets
    AppServiceEnvironments = $ases
    ContainerAppEnvironments = $caes
    WebApps = $webApps
    ContainerApps = $containerApps
    AppGateways = $appGateways
    Databases = $databases
}

$outputPath = "$PSScriptRoot\output"
if (!(Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force
}

$jsonPath = "$outputPath\team-$TeamName-resources.json"
$teamResources | ConvertTo-Json -Depth 10 > $jsonPath
Write-Host "Exported resources for Team $TeamName to $jsonPath"
