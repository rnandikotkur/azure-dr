
# Setup-DiagramEnvironment.ps1
# This script helps set up the environment for generating Azure architecture diagrams

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$InstallModules,
    
    [Parameter()]
    [switch]$ConnectToAzure,
    
    [Parameter()]
    [switch]$CreateSampleTeams
)

# Display banner
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "       Azure Architecture Diagram Generator Setup      " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Patch)" -ForegroundColor Yellow
if ($psVersion.Major -lt 7) {
    Write-Host "NOTE: PowerShell 7+ is recommended for best results." -ForegroundColor Yellow
}

# Create output directory if it doesn't exist
$outputDir = "$PSScriptRoot\output"
if (!(Test-Path $outputDir)) {
    Write-Host "Creating output directory..." -ForegroundColor Green
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "Created: $outputDir" -ForegroundColor Green
}

# Install required modules if requested
if ($InstallModules) {
    Write-Host "Installing required PowerShell modules..." -ForegroundColor Green
    
    # Check for Az module
    if (!(Get-Module -ListAvailable -Name Az)) {
        Write-Host "Installing Az module..." -ForegroundColor Yellow
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    } else {
        Write-Host "Az module already installed." -ForegroundColor Green
    }
    
    # Check for ImportExcel module (optional but recommended)
    if (!(Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "Installing ImportExcel module..." -ForegroundColor Yellow
        Install-Module -Name ImportExcel -Scope CurrentUser -Repository PSGallery -Force
    } else {
        Write-Host "ImportExcel module already installed." -ForegroundColor Green
    }
}

# Connect to Azure if requested
if ($ConnectToAzure) {
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    try {
        Connect-AzAccount
        Write-Host "Successfully connected to Azure." -ForegroundColor Green
        
        # Display current subscription
        $context = Get-AzContext
        Write-Host "Current subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to connect to Azure: $_" -ForegroundColor Red
    }
}

# Create sample teams.txt file if requested
if ($CreateSampleTeams) {
    Write-Host "Creating sample teams.txt file..." -ForegroundColor Green
    @"
Team1
Team2
Team3
Team4
Team5
Team6
Team7
Team8
Team9
Team10
Team11
"@ | Out-File -FilePath "$PSScriptRoot\teams.txt" -Force
    Write-Host "Created sample teams.txt file at $PSScriptRoot\teams.txt" -ForegroundColor Green
}

# Display next steps
Write-Host ""
Write-Host "Setup Complete! Next Steps:" -ForegroundColor Green
Write-Host "1. Ensure your Azure resources have appropriate 'Team' tags" -ForegroundColor White
Write-Host "2. Run one of the following commands:" -ForegroundColor White
Write-Host "   - Generate diagrams for all teams: .\Generate-AllTeamDiagrams.ps1 -DiscoverTeams" -ForegroundColor Cyan
Write-Host "   - Generate a diagram for a specific team: .\Generate-TeamDiagram.ps1 -TeamName 'Team1'" -ForegroundColor Cyan
Write-Host "   - Export resource inventory: .\Export-ResourceInventory.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "For more details, see the README.md file" -ForegroundColor White
