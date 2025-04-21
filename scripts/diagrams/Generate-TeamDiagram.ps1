
# Generate-TeamDiagram.ps1
# This script generates an SVG architecture diagram based on the JSON data from Query-TeamResources.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$TeamName,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$PSScriptRoot\output"
)

# Import the JSON data
$jsonFile = "$OutputPath\team-$TeamName-resources.json"
if (!(Test-Path $jsonFile)) {
    Write-Error "JSON file for team $TeamName not found at $jsonFile. Run Query-TeamResources.ps1 first."
    exit 1
}

Write-Host "Generating architecture diagram for Team $TeamName"
$teamResources = Get-Content $jsonFile | ConvertFrom-Json

# Initialize SVG dimensions based on resource count
$totalResources = ($teamResources.WebApps.Count + $teamResources.ContainerApps.Count + $teamResources.Databases.Count)
$height = [Math]::Max(600, 200 + ($totalResources * 30))
$width = 800

# Start building the SVG
$svgHeader = @"
<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
  <!-- Title -->
  <text x="400" y="30" font-family="Arial" font-size="20" text-anchor="middle" font-weight="bold">Team $TeamName - Detailed Architecture</text>
  
  <!-- Legend -->
  <rect x="620" y="50" width="160" height="180" fill="#f0f0f0" stroke="#000000" stroke-width="1" />
  <text x="700" y="70" font-family="Arial" font-size="12" text-anchor="middle" font-weight="bold">Legend</text>
  <rect x="630" y="80" width="20" height="20" fill="#b3d1ff" stroke="#000000" stroke-width="1" />
  <text x="655" y="95" font-family="Arial" font-size="10" x-anchor="start">VNet/Subnet</text>
  <rect x="630" y="105" width="20" height="20" fill="#ffcccc" stroke="#000000" stroke-width="1" rx="3" ry="3" />
  <text x="655" y="120" font-family="Arial" font-size="10" x-anchor="start">ASE</text>
  <rect x="630" y="130" width="20" height="20" fill="#d9f2d9" stroke="#000000" stroke-width="1" rx="3" ry="3" />
  <text x="655" y="145" font-family="Arial" font-size="10" x-anchor="start">Container App Env</text>
  <rect x="630" y="155" width="20" height="20" fill="#ffffff" stroke="#000000" stroke-width="1" />
  <text x="655" y="170" font-family="Arial" font-size="10" x-anchor="start">Web/Function App</text>
  <rect x="630" y="180" width="20" height="20" fill="#ffe6cc" stroke="#000000" stroke-width="1" />
  <text x="655" y="195" font-family="Arial" font-size="10" x-anchor="start">Database</text>
  <rect x="630" y="205" width="20" height="20" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="655" y="220" font-family="Arial" font-size="10" x-anchor="start">App Gateway</text>
  
  <!-- Define arrowhead marker -->
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#000000" />
    </marker>
  </defs>
"@

# App Gateway Section
$svgAppGw = ""
if ($teamResources.AppGateways.Count -gt 0) {
    $appGw = $teamResources.AppGateways[0]
    $svgAppGw = @"
  
  <!-- App Gateway -->
  <rect x="40" y="80" width="120" height="40" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="100" y="105" font-family="Arial" font-size="12" text-anchor="middle">App Gateway</text>
  <text x="100" y="120" font-family="Arial" font-size="10" text-anchor="middle">$($appGw.name)</text>
  
"@
}

$svgVnets = ""
# Process VNets
if ($teamResources.VirtualNetworks.Count -gt 0) {
    foreach ($vnet in $teamResources.VirtualNetworks) {
        # Extract address space if available
        $addressPrefix = "Unknown"
        if ($vnet.properties.addressSpace.addressPrefixes) {
            $addressPrefix = $vnet.properties.addressSpace.addressPrefixes[0]
        }
        
        $svgVnets += @"
  
  <!-- Team $TeamName Virtual Network -->
  <rect x="20" y="140" width="580" height="$($height - 160)" fill="#b3d1ff" stroke="#0066cc" stroke-width="2" />
  <text x="30" y="160" font-family="Arial" font-size="14" font-weight="bold">$($vnet.name) ($addressPrefix)</text>
  <text x="30" y="180" font-family="Arial" font-size="12">Resource Group: $($vnet.resourceGroup)</text>
  
"@
    }
} else {
    # If no VNet, still create a container
    $svgVnets += @"
  
  <!-- Team $TeamName Resources -->
  <rect x="20" y="140" width="580" height="$($height - 160)" fill="#f9f9f9" stroke="#000000" stroke-width="1" />
  <text x="30" y="160" font-family="Arial" font-size="14" font-weight="bold">Team $TeamName Resources</text>
  
"@
}

$svgAses = ""
$yPosition = 200
# Process ASEs
if ($teamResources.AppServiceEnvironments.Count -gt 0) {
    foreach ($ase in $teamResources.AppServiceEnvironments) {
        $internal = $ase.properties.internalLoadBalancingMode -ne "None"
        $internalText = if ($internal) { "Internal" } else { "External" }
        
        $svgAses += @"
  
  <!-- ASE Section -->
  <rect x="40" y="$yPosition" width="260" height="220" fill="#ffcccc" stroke="#ff6666" stroke-width="1" rx="5" ry="5" />
  <text x="50" y="$($yPosition + 20)" font-family="Arial" font-size="14" font-weight="bold">ASE ($internalText)</text>
  <text x="50" y="$($yPosition + 40)" font-family="Arial" font-size="12">Name: $($ase.name)</text>
  <text x="50" y="$($yPosition + 60)" font-family="Arial" font-size="12">Resource Group: $($ase.resourceGroup)</text>
  
"@

        # Add Web Apps for this ASE
        $appYPos = $yPosition + 80
        $appXPos = 60
        $aseWebApps = $teamResources.WebApps | Where-Object { $_.hostingEnvId -match $ase.id }
        
        foreach ($app in $aseWebApps) {
            # Determine if it's a web app or function app
            $appType = "Web App"
            if ($app.kind -match "function") {
                $appType = "Function App"
            }
            
            $svgAses += @"
      
    <rect x="$appXPos" y="$appYPos" width="100" height="40" fill="white" stroke="#000000" stroke-width="1" />
    <text x="$($appXPos + 50)" y="$($appYPos + 20)" font-family="Arial" font-size="12" text-anchor="middle">$appType</text>
    <text x="$($appXPos + 50)" y="$($appYPos + 35)" font-family="Arial" font-size="10" text-anchor="middle">$($app.name)</text>
    
"@
            $appXPos += 120
            if ($appXPos > 200) {
                $appXPos = 60
                $appYPos += 50
            }
        }
        
        $yPosition += 240
    }
}

$svgCaes = ""
$yPosition = 200
# Process Container App Environments
if ($teamResources.ContainerAppEnvironments.Count -gt 0) {
    foreach ($cae in $teamResources.ContainerAppEnvironments) {
        $svgCaes += @"
    
    <!-- Container App Environment -->
    <rect x="320" y="$yPosition" width="260" height="220" fill="#d9f2d9" stroke="#33cc33" stroke-width="1" rx="5" ry="5" />
    <text x="330" y="$($yPosition + 20)" font-family="Arial" font-size="14" font-weight="bold">Container App Environment</text>
    <text x="330" y="$($yPosition + 40)" font-family="Arial" font-size="12">Name: $($cae.name)</text>
    <text x="330" y="$($yPosition + 60)" font-family="Arial" font-size="12">Resource Group: $($cae.resourceGroup)</text>
    
"@

        # Add Container Apps for this environment
        $appYPos = $yPosition + 80
        $appXPos = 340
        $caeApps = $teamResources.ContainerApps | Where-Object { $_.envId -match $cae.id }
        
        foreach ($app in $caeApps) {
            $svgCaes += @"
        
    <rect x="$appXPos" y="$appYPos" width="100" height="40" fill="white" stroke="#000000" stroke-width="1" rx="2" ry="2" />
    <text x="$($appXPos + 50)" y="$($appYPos + 20)" font-family="Arial" font-size="12" text-anchor="middle">Container App</text>
    <text x="$($appXPos + 50)" y="$($appYPos + 35)" font-family="Arial" font-size="10" text-anchor="middle">$($app.name)</text>
    
"@
            $appXPos += 120
            if ($appXPos > 480) {
                $appXPos = 340
                $appYPos += 50
            }
        }
        
        $yPosition += 240
    }
}

# Non-ASE Web Apps (if any)
$nonAseWebApps = $teamResources.WebApps | Where-Object { -not $_.hostingEnvId }
if ($nonAseWebApps.Count -gt 0) {
    $svgPublicApps = @"
  
  <!-- Public Web & Function Apps -->
  <rect x="40" y="$yPosition" width="540" height="120" fill="#ffffff" stroke="#999999" stroke-width="1" />
  <text x="50" y="$($yPosition + 20)" font-family="Arial" font-size="14" font-weight="bold">Public App Services</text>
  
"@

    $appYPos = $yPosition + 40
    $appXPos = 60
    foreach ($app in $nonAseWebApps) {
        $appType = "Web App"
        if ($app.kind -match "function") {
            $appType = "Function App"
        }
        
        $svgPublicApps += @"
    
  <rect x="$appXPos" y="$appYPos" width="100" height="40" fill="white" stroke="#000000" stroke-width="1" />
  <text x="$($appXPos + 50)" y="$($appYPos + 20)" font-family="Arial" font-size="12" text-anchor="middle">$appType</text>
  <text x="$($appXPos + 50)" y="$($appYPos + 35)" font-family="Arial" font-size="10" text-anchor="middle">$($app.name)</text>
  
"@
        $appXPos += 120
        if ($appXPos > 480) {
            $appXPos = 60
            $appYPos += 50
        }
    }
    
    $yPosition += 140
} else {
    $svgPublicApps = ""
}

# Calculate position for databases section
$dbYPosition = [Math]::Max($yPosition, $height - 150)

$svgDatabases = @"

  <!-- Databases -->
  <rect x="40" y="$dbYPosition" width="540" height="100" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="50" y="$($dbYPosition + 20)" font-family="Arial" font-size="14" font-weight="bold">Team $TeamName Databases</text>
  
"@

# Add database instances
$dbXPos = 60
$dbYPos = $dbYPosition + 40
if ($teamResources.Databases.Count -gt 0) {
    foreach ($db in $teamResources.Databases) {
        $dbType = "Database"
        if ($db.type -match "Sql") {
            $dbType = "SQL Database"
        } elseif ($db.type -match "DocumentDB") {
            $dbType = "Cosmos DB"
        } elseif ($db.type -match "MySQL") {
            $dbType = "MySQL"
        } elseif ($db.type -match "Redis") {
            $dbType = "Redis Cache"
        }
        
        $svgDatabases += @"
    
    <rect x="$dbXPos" y="$dbYPos" width="120" height="20" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
    <text x="$($dbXPos + 60)" y="$($dbYPos + 15)" font-family="Arial" font-size="10" text-anchor="middle">$dbType: $($db.name)</text>
    
"@
        $dbXPos += 140
        if ($dbXPos > 450) {
            $dbXPos = 60
            $dbYPos += 30
        }
    }
} else {
    $svgDatabases += @"
    
    <text x="310" y="$($dbYPosition + 50)" font-family="Arial" font-size="12" text-anchor="middle">No database resources found</text>
    
"@
}

$svgFooter = @"

</svg>
"@

# Combine all parts of the SVG
$completeSvg = $svgHeader + $svgAppGw + $svgVnets + $svgAses + $svgCaes + $svgPublicApps + $svgDatabases + $svgFooter

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force
}

# Save the SVG to a file
$svgPath = "$OutputPath\team-$TeamName-architecture.svg"
$completeSvg | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "Generated architecture diagram for Team $TeamName saved to $svgPath"
