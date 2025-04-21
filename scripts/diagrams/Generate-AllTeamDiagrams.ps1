
# Generate-AllTeamDiagrams.ps1
# Master script to generate diagrams for all teams
# Discovers all teams with tagged resources in Azure

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
    
    # Save discovered teams to file for future use
    $teams | Out-File -FilePath "$OutputPath\discovered-teams.txt"
    Write-Host "Saved team list to $OutputPath\discovered-teams.txt"
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

Write-Host "Processing $($teams.Count) teams: $($teams -join ', ')"

# Process each team
foreach ($team in $teams) {
    Write-Host "`n==== Processing Team: $team ====" -ForegroundColor Green
    
    # Run the query script
    & "$PSScriptRoot\Query-TeamResources.ps1" -TeamName $team
    
    # Generate the SVG diagram
    & "$PSScriptRoot\Generate-TeamDiagram.ps1" -TeamName $team -OutputPath $OutputPath
}

Write-Host "`nAll team diagrams generated successfully in $OutputPath!" -ForegroundColor Green
