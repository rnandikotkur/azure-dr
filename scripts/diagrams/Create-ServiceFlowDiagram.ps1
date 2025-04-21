
# Create-ServiceFlowDiagram.ps1
# This script generates a service flow diagram showing the request path through Azure resources

param(
    [Parameter(Mandatory=$true)]
    [string]$TeamName,
    
    [Parameter(Mandatory=$true)]
    [string]$FlowName,
    
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

Write-Host "Generating service flow diagram: $FlowName for Team $TeamName"

# Get team resources
$jsonFile = "$OutputPath\team-$TeamName-resources.json"
if (!(Test-Path $jsonFile)) {
    Write-Host "JSON file for team $TeamName not found. Running resource query..."
    & "$PSScriptRoot\Query-TeamResources.ps1" -TeamName $TeamName
    
    if (!(Test-Path $jsonFile)) {
        Write-Error "Failed to create team resources JSON file. Aborting."
        exit 1
    }
}

$teamResources = Get-Content $jsonFile | ConvertFrom-Json

# Start building the SVG
$svgHeader = @"
<svg viewBox="0 0 800 400" xmlns="http://www.w3.org/2000/svg">
  <!-- Title -->
  <text x="400" y="30" font-family="Arial" font-size="20" text-anchor="middle" font-weight="bold">Team $TeamName - $FlowName Flow</text>
  
  <!-- Define arrowhead marker -->
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#000000" />
    </marker>
  </defs>
"@

# Create a generic flow - this can be customized based on your specific requirements
$svgFlow = @"
  
  <!-- Entities and Flow -->
  <rect x="50" y="70" width="100" height="50" fill="#f5f5f5" stroke="#000000" stroke-width="1" />
  <text x="100" y="100" font-family="Arial" font-size="12" text-anchor="middle">User Browser</text>
"@

# Add App Gateway if it exists
if ($teamResources.AppGateways.Count -gt 0) {
    $appGw = $teamResources.AppGateways[0]
    $svgFlow += @"
  
  <rect x="200" y="70" width="100" height="50" fill="#fff2cc" stroke="#d6b656" stroke-width="1" rx="5" ry="5" />
  <text x="250" y="100" font-family="Arial" font-size="12" text-anchor="middle">App Gateway</text>
  <text x="250" y="115" font-family="Arial" font-size="10" text-anchor="middle">$($appGw.name)</text>
  
  <!-- Flow Arrow -->
  <path d="M 150,95 L 200,95" stroke="#000000" stroke-width="1" marker-end="url(#arrow)" />
  <text x="175" y="85" font-family="Arial" font-size="10" text-anchor="middle">HTTPS</text>
"@
    $lastX = 300
} else {
    $lastX = 150
}

# Add Web App (if any)
if ($teamResources.WebApps.Count -gt 0) {
    $webApp = $teamResources.WebApps[0]
    $appType = "Web App"
    if ($webApp.kind -match "function") {
        $appType = "Function App"
    }
    
    $isInAse = [bool]$webApp.hostingEnvId
    $fill = "#ffffff"
    $stroke = "#000000"
    if ($isInAse) {
        $fill = "#ffcccc"
        $stroke = "#ff6666"
    }
    
    $svgFlow += @"
  
  <rect x="$lastX" y="70" width="100" height="50" fill="$fill" stroke="$stroke" stroke-width="1" />
  <text x="$($lastX + 50)" y="100" font-family="Arial" font-size="12" text-anchor="middle">$appType</text>
  <text x="$($lastX + 50)" y="115" font-family="Arial" font-size="10" text-anchor="middle">$($webApp.name)</text>
  
  <!-- Flow Arrow -->
  <path d="M $($lastX - 50),95 L $lastX,95" stroke="#000000" stroke-width="1" marker-end="url(#arrow)" />
  <text x="$($lastX - 25)" y="85" font-family="Arial" font-size="10" text-anchor="middle">HTTPS</text>
"@
    $lastX += 150
}

# Add Container App (if any)
if ($teamResources.ContainerApps.Count -gt 0) {
    $containerApp = $teamResources.ContainerApps[0]
    
    $svgFlow += @"
  
  <rect x="$lastX" y="70" width="100" height="50" fill="#d9f2d9" stroke="#33cc33" stroke-width="1" />
  <text x="$($lastX + 50)" y="100" font-family="Arial" font-size="12" text-anchor="middle">API Service</text>
  <text x="$($lastX + 50)" y="115" font-family="Arial" font-size="10" text-anchor="middle">$($containerApp.name)</text>
  
  <!-- Flow Arrow -->
  <path d="M $($lastX - 50),95 L $lastX,95" stroke="#000000" stroke-width="1" marker-end="url(#arrow)" />
  <text x="$($lastX - 25)" y="85" font-family="Arial" font-size="10" text-anchor="middle">HTTPS</text>
"@
    $lastX += 150
}

# Add Database (if any)
if ($teamResources.Databases.Count -gt 0) {
    $database = $teamResources.Databases[0]
    $dbType = "Database"
    if ($database.type -match "Sql") {
        $dbType = "SQL Database"
    } elseif ($database.type -match "DocumentDB") {
        $dbType = "Cosmos DB"
    } elseif ($database.type -match "MySQL") {
        $dbType = "MySQL"
    } elseif ($database.type -match "Redis") {
        $dbType = "Redis Cache"
    }
    
    $svgFlow += @"
  
  <rect x="$lastX" y="70" width="100" height="50" fill="#ffe6cc" stroke="#d79b00" stroke-width="1" />
  <text x="$($lastX + 50)" y="100" font-family="Arial" font-size="12" text-anchor="middle">$dbType</text>
  <text x="$($lastX + 50)" y="115" font-family="Arial" font-size="10" text-anchor="middle">$($database.name)</text>
  
  <!-- Flow Arrow -->
  <path d="M $($lastX - 50),95 L $lastX,95" stroke="#000000" stroke-width="1" marker-end="url(#arrow)" />
  <text x="$($lastX - 25)" y="85" font-family="Arial" font-size="10" text-anchor="middle">DB Protocol</text>
"@
}

# Add flow details section
$svgFlowDetails = @"

  <!-- Flow Details -->
  <rect x="50" y="150" width="700" height="220" fill="#f9f9f9" stroke="#000000" stroke-width="1" />
  <text x="60" y="170" font-family="Arial" font-size="14" font-weight="bold">Request Flow Details:</text>
  
  <text x="60" y="200" font-family="Arial" font-size="12">1. User navigates to the application endpoint</text>
  <text x="60" y="220" font-family="Arial" font-size="12">2. DNS resolves to App Gateway/Load Balancer</text>
  <text x="60" y="240" font-family="Arial" font-size="12">3. App Gateway routes traffic to appropriate compute service</text>
  <text x="60" y="260" font-family="Arial" font-size="12">4. Application logic processes the request</text>
  <text x="60" y="280" font-family="Arial" font-size="12">5. API services are called as needed for business operations</text>
  <text x="60" y="300" font-family="Arial" font-size="12">6. Database operations fetch or store required data</text>
  <text x="60" y="320" font-family="Arial" font-size="12">7. Response returns through the chain back to the user</text>
  
  <text x="60" y="350" font-family="Arial" font-size="12" font-weight="bold">Authentication:</text>
  <text x="180" y="350" font-family="Arial" font-size="12">Azure AD for user authentication, Managed Identity for service-to-service</text>
"@

$svgFooter = @"

</svg>
"@

# Combine all parts of the SVG
$completeSvg = $svgHeader + $svgFlow + $svgFlowDetails + $svgFooter

# Save the SVG to a file
$svgPath = "$OutputPath\$TeamName-$($FlowName.Replace(' ', '-'))-flow.svg"
$completeSvg | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "Generated service flow diagram saved to $svgPath"
