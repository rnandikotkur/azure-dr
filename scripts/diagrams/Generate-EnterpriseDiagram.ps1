
# Generate-EnterpriseDiagram.ps1
# This script generates an enterprise-level overview diagram showing all teams

param(
    [Parameter(Mandatory=$false)]
    [string]$TeamsFile = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DiscoverTeams,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$PSScriptRoot\output"
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

$teams = @()

# Option 1: Discover teams from resource tags
if ($DiscoverTeams) {
    Write-Host "Discovering teams from Azure resource tags..."
    
    $teamsQuery = @"
    Resources
    | where tags.Team != ""
    | project Team = tostring(tags.Team)
    | distinct Team
    | order by Team asc
"@
    
    $teamsResult = Search-AzGraph -Query $teamsQuery
    $teams = $teamsResult.Team
    
    Write-Host "Discovered $($teams.Count) teams"
}
# Option 2: Load teams from file
elseif ($TeamsFile -and (Test-Path $TeamsFile)) {
    Write-Host "Loading teams from file: $TeamsFile"
    $teams = Get-Content $TeamsFile | Where-Object { $_ -match '\S' } # Skip empty lines
}
# Option 3: No teams specified
else {
    Write-Error "No teams specified. Either use -DiscoverTeams switch or provide a teams file with -TeamsFile"
    exit 1
}

Write-Host "Generating enterprise overview for $($teams.Count) teams"

# Query shared services
$sharedServicesQuery = @"
Resources
| where tags.Team =~ 'Shared' or tags.Purpose =~ 'Shared'
| where type in~ ('Microsoft.Network/applicationGateways', 'Microsoft.ApiManagement/service', 
                  'Microsoft.OperationalInsights/workspaces', 'Microsoft.KeyVault/vaults')
| project name, type, resourceGroup
"@

$sharedServices = Search-AzGraph -Query $sharedServicesQuery

# Query team environments
$teamEnvsQuery = @"
Resources
| where tags.Team != ""
| extend Team = tostring(tags.Team)
| where Team != "Shared"
| extend ASE = iff(type =~ 'Microsoft.Web/hostingEnvironments', 1, 0)
| extend ContainerApp = iff(type =~ 'Microsoft.App/managedEnvironments', 1, 0)
| extend PublicApp = iff(type =~ 'Microsoft.Web/sites' and not(properties.hostingEnvironmentProfile.id != ""), 1, 0)
| summarize HasASE = max(ASE), HasContainerApp = max(ContainerApp), HasPublicApp = max(PublicApp) by Team
"@

$teamEnvironments = Search-AzGraph -Query $teamEnvsQuery

# Query VNets to get address spaces
$vnetQuery = @"
Resources
| where type =~ 'Microsoft.Network/virtualNetworks'
| where tags.Team != ""
| extend Team = tostring(tags.Team)
| project Team, name, properties.addressSpace.addressPrefixes
| order by Team asc
"@

$vnets = Search-AzGraph -Query $vnetQuery

# Calculate layout
$teamCount = $teams.Count
$cols = [Math]::Min(3, $teamCount)
$rows = [Math]::Ceiling($teamCount / $cols)
$boxWidth = 180
$boxHeight = 120
$margin = 20
$width = ($boxWidth * $cols) + ($margin * ($cols + 1))
$height = 150 + ($boxHeight * ($rows + 1)) + ($margin * ($rows + 2))

# Start building the SVG
$svgHeader = @"
<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
  <!-- Title -->
  <text x="$($width / 2)" y="30" font-family="Arial" font-size="20" text-anchor="middle" font-weight="bold">Enterprise Azure Architecture Overview</text>
  
  <!-- Legend -->
  <rect x="$($width - 180)" y="50" width="160" height="180" fill="#f0f0f0" stroke="#000000" stroke-width="1" />
  <text x="$($width - 100)" y="70" font-family="Arial" font-size="12" text-anchor="middle" font-weight="bold">Legend</text>
  <rect x="$($width - 170)" y="80" width="20" height="20" fill="#b3d1ff" stroke="#000000" stroke-width="1" />
  <text x="$($width - 145)" y="95" font-family="Arial" font-size="10" x-anchor="start">VNet</text>
  <rect x="$($width - 170)" y="105" width="20" height="20" fill="#ffcccc" stroke="#000000" stroke-width="1" rx="3" ry="3" />
  <text x="$($width - 145)" y="120" font-family="Arial" font-size="10" x-anchor="start">ASE</text>
  <rect x="$($width - 170)" y="130" width="20" height="20" fill="#d9f2d9" stroke="#000000" stroke-width="1" rx="3" ry="3" />
  <text x="$($width - 145)" y="145" font-family="Arial" font-size="10" x-anchor="start">Container App Env</text>
  <rect x="$($width - 170)" y="155" width="20" height="20" fill="#ffffff" stroke="#000000" stroke-width="1" />
  <text x="$($width - 145)" y="170" font-family="Arial" font-size="10" x-anchor="start">Public Resources</text>
  <rect x="$($width - 170)" y="180" width="20" height="20" fill="#ffe6cc" stroke="#000000" stroke-width="1" />
  <text x="$($width - 145)" y="195" font-family="Arial" font-size="10" x-anchor="start">Databases</text>
  <rect x="$($width - 170)" y="205" width="20" height="20" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="$($width - 145)" y="220" font-family="Arial" font-size="10" x-anchor="start">Shared Services</text>
"@

# Shared Services Section
$svgSharedServices = @"
  
  <!-- Shared Services -->
  <rect x="$margin" y="50" width="$($width - $margin*2)" height="80" fill="#e6f2ff" stroke="#000000" stroke-width="1" />
  <text x="$($margin + 10)" y="70" font-family="Arial" font-size="16" font-weight="bold">Shared Services</text>
  
"@

# Add specific shared services
$ssX = $margin + 20
$appGw = $sharedServices | Where-Object { $_.type -like "*applicationGateways*" } | Select-Object -First 1
if ($appGw) {
    $svgSharedServices += @"
  <rect x="$ssX" y="80" width="100" height="40" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="$($ssX + 50)" y="105" font-family="Arial" font-size="12" text-anchor="middle">App Gateway</text>
"@
    $ssX += 120
}

$apim = $sharedServices | Where-Object { $_.type -like "*ApiManagement*" } | Select-Object -First 1
if ($apim) {
    $svgSharedServices += @"
  <rect x="$ssX" y="80" width="100" height="40" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="$($ssX + 50)" y="105" font-family="Arial" font-size="12" text-anchor="middle">APIM</text>
"@
    $ssX += 120
}

$monitor = $sharedServices | Where-Object { $_.type -like "*OperationalInsights*" } | Select-Object -First 1
if ($monitor) {
    $svgSharedServices += @"
  <rect x="$ssX" y="80" width="100" height="40" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="$($ssX + 50)" y="105" font-family="Arial" font-size="12" text-anchor="middle">Azure Monitor</text>
"@
    $ssX += 120
}

$keyVault = $sharedServices | Where-Object { $_.type -like "*KeyVault*" } | Select-Object -First 1
if ($keyVault) {
    $svgSharedServices += @"
  <rect x="$ssX" y="80" width="100" height="40" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="$($ssX + 50)" y="105" font-family="Arial" font-size="12" text-anchor="middle">Key Vault</text>
"@
}

# Teams Section
$svgTeams = ""
$rowY = 140
$colX = $margin

# Create team boxes
for ($i = 0; $i -lt $teams.Count; $i++) {
    $team = $teams[$i]
    $teamEnv = $teamEnvironments | Where-Object { $_.Team -eq $team }
    
    # If we've reached the maximum columns, start a new row
    if ($i % $cols -eq 0 -and $i -gt 0) {
        $rowY += $boxHeight + $margin
        $colX = $margin
    }
    
    # Get team's VNet address space if available
    $teamVNet = $vnets | Where-Object { $_.Team -eq $team } | Select-Object -First 1
    $addressSpace = "VNet"
    if ($teamVNet -and $teamVNet.properties_addressSpace_addressPrefixes) {
        $addressSpace = $teamVNet.properties_addressSpace_addressPrefixes[0]
    }
    
    $svgTeams += @"
    
  <!-- Team $team Box -->
  <rect x="$colX" y="$rowY" width="$boxWidth" height="$boxHeight" fill="#f9f9f9" stroke="#000000" stroke-width="1" />
  <text x="$($colX + 10)" y="$($rowY + 20)" font-family="Arial" font-size="16" font-weight="bold">Team $team</text>
  <rect x="$($colX + 10)" y="$($rowY + 30)" width="$($boxWidth - 20)" height="$($boxHeight - 40)" fill="#b3d1ff" stroke="#0066cc" stroke-width="2" />
  <text x="$($colX + $boxWidth/2)" y="$($rowY + 60)" font-family="Arial" font-size="12" text-anchor="middle">$addressSpace</text>
"@

    # Add environment icons
    $envY = $rowY + 80
    $envX = $colX + 20
    
    if ($teamEnv.HasASE -eq 1) {
        $svgTeams += @"
        
  <rect x="$envX" y="$envY" width="20" height="20" fill="#ffcccc" stroke="#ff6666" stroke-width="1" rx="3" ry="3" />
"@
        $envX += 30
    }
    
    if ($teamEnv.HasContainerApp -eq 1) {
        $svgTeams += @"
        
  <rect x="$envX" y="$envY" width="20" height="20" fill="#d9f2d9" stroke="#33cc33" stroke-width="1" rx="3" ry="3" />
"@
        $envX += 30
    }
    
    if ($teamEnv.HasPublicApp -eq 1) {
        $svgTeams += @"
        
  <rect x="$envX" y="$envY" width="20" height="20" fill="#ffffff" stroke="#000000" stroke-width="1" />
"@
    }
    
    $colX += $boxWidth + $margin
}

# Data Services Section
$dataY = $rowY + $boxHeight + $margin
$svgDataServices = @"

  <!-- Shared Data Services -->
  <rect x="$margin" y="$dataY" width="$($width - $margin*2)" height="60" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 10)" y="$($dataY + 20)" font-family="Arial" font-size="16" font-weight="bold">Shared Data Services</text>
  
  <!-- Database Types -->
  <rect x="$($margin + 20)" y="$($dataY + 30)" width="80" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 60)" y="$($dataY + 45)" font-family="Arial" font-size="10" text-anchor="middle">SQL DBs</text>
  
  <rect x="$($margin + 110)" y="$($dataY + 30)" width="80" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 150)" y="$($dataY + 45)" font-family="Arial" font-size="10" text-anchor="middle">Cosmos DB</text>
  
  <rect x="$($margin + 200)" y="$($dataY + 30)" width="80" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 240)" y="$($dataY + 45)" font-family="Arial" font-size="10" text-anchor="middle">MySQL</text>
  
  <rect x="$($margin + 290)" y="$($dataY + 30)" width="80" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 330)" y="$($dataY + 45)" font-family="Arial" font-size="10" text-anchor="middle">Redis Cache</text>
  
  <rect x="$($margin + 380)" y="$($dataY + 30)" width="80" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($margin + 420)" y="$($dataY + 45)" font-family="Arial" font-size="10" text-anchor="middle">Storage</text>
"@

$svgFooter = @"

</svg>
"@

# Combine all parts of the SVG
$completeSvg = $svgHeader + $svgSharedServices + $svgTeams + $svgDataServices + $svgFooter

# Save the SVG to a file
$svgPath = "$OutputPath\enterprise-architecture.svg"
$completeSvg | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "Generated enterprise architecture diagram saved to $svgPath"
