# Azure Architecture Diagram Generation

This collection of PowerShell scripts automatically generates architecture diagrams and detailed documentation for Azure environments using Azure Resource Graph queries. It's designed to help you document complex Azure environments with multiple teams and services, providing both visual diagrams and tabular documentation.

## Overview

These scripts help you:

1. **Automatically generate architecture diagrams** from your actual Azure resources
2. **Document team-specific architectures** including compute services, networking, and databases
3. **Create service flow diagrams** showing how requests move through your architecture
4. **Export comprehensive resource inventories** for documentation and tracking
5. **Generate enterprise-level overviews** showing all teams and shared services

## Prerequisites

- PowerShell 7.0+ (recommended, though 5.1 should work for most scripts)
- Az PowerShell module
- Azure CLI (optional, for some advanced tasks)
- ImportExcel PowerShell module (optional, for Excel exports)

### Installation

1. Install required PowerShell modules:

```powershell
# Install required modules
Install-Module -Name Az -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser

# Connect to Azure
Connect-AzAccount
```

2. Clone or download this repository to your local machine
3. Ensure your Azure resources are properly tagged with at least a `Team` tag

## Available Scripts

### Core Scripts

| Script | Description |
|--------|-------------|
| `Query-TeamResources.ps1` | Queries all resources for a specific team using Azure Resource Graph |
| `Generate-TeamDiagram.ps1` | Creates an SVG architecture diagram for a specific team |
| `Generate-AllTeamDiagrams.ps1` | Discovers all teams and generates diagrams for each |
| `Generate-EnterpriseDiagram.ps1` | Creates a high-level enterprise architecture overview diagram |
| `Create-ServiceFlowDiagram.ps1` | Generates service flow diagrams showing request paths |
| `Export-ResourceInventory.ps1` | Exports comprehensive resource inventory to Excel/CSV |

## Tagging Requirements

For best results, apply these tags to your Azure resources:

- **Team**: (Required) The team responsible for the resource (e.g., "Team1", "Team2", etc.)
- **Environment**: The environment type (e.g., "Production", "Development")
- **ServiceName**: Logical service name that groups related resources
- **AccessType**: "Internal" or "External" for compute resources
- **CustomDomain**: Any custom domain associated with the service
- **Purpose**: Additional context about the resource's purpose

## Quick Start

### Generate diagrams for all teams

```powershell
# Navigate to the scripts directory
cd /path/to/scripts/diagrams

# Discover teams and generate all diagrams
.\Generate-AllTeamDiagrams.ps1 -DiscoverTeams
```

### Generate a diagram for a specific team

```powershell
.\Generate-TeamDiagram.ps1 -TeamName "Team1"
```

### Create a service flow diagram

```powershell
.\Create-ServiceFlowDiagram.ps1 -TeamName "Team1" -FlowName "Customer Portal"
```

### Export a comprehensive resource inventory

```powershell
.\Export-ResourceInventory.ps1
```

## Detailed Usage

### Query-TeamResources.ps1

This script queries all Azure resources belonging to a specific team.

```powershell
.\Query-TeamResources.ps1 -TeamName "Team1"
```

**Parameters:**
- `-TeamName` (Required): The name of the team to query resources for

**Output:**
- Creates a JSON file in the `output` directory with all team resources

### Generate-TeamDiagram.ps1

This script generates an SVG architecture diagram for a specific team.

```powershell
.\Generate-TeamDiagram.ps1 -TeamName "Team1" -OutputPath "C:\Documentation"
```

**Parameters:**
- `-TeamName` (Required): The name of the team to generate a diagram for
- `-OutputPath` (Optional): Path where the diagram should be saved (default: .\output)

**Output:**
- Creates an SVG file showing the team's architecture

### Generate-AllTeamDiagrams.ps1

This script discovers all teams and generates diagrams for each one.

```powershell
# Discover teams automatically
.\Generate-AllTeamDiagrams.ps1 -DiscoverTeams

# Or use a specific list of teams
.\Generate-AllTeamDiagrams.ps1 -TeamsFile "teams.txt"
```

**Parameters:**
- `-DiscoverTeams`: Automatically discover teams from Azure resource tags
- `-TeamsFile`: Path to a text file containing team names (one per line)
- `-OutputPath` (Optional): Path where diagrams should be saved (default: .\output)

**Output:**
- Creates SVG files for each team's architecture

### Generate-EnterpriseDiagram.ps1

This script creates a high-level enterprise architecture overview.

```powershell
.\Generate-EnterpriseDiagram.ps1 -DiscoverTeams
```

**Parameters:**
- `-DiscoverTeams`: Automatically discover teams from Azure resource tags
- `-TeamsFile`: Path to a text file containing team names (one per line)
- `-OutputPath` (Optional): Path where the diagram should be saved (default: .\output)

**Output:**
- Creates an SVG file showing the enterprise-level architecture

### Create-ServiceFlowDiagram.ps1

This script generates diagrams showing how requests flow through your architecture.

```powershell
.\Create-ServiceFlowDiagram.ps1 -TeamName "Team1" -FlowName "Customer Portal"
```

**Parameters:**
- `-TeamName` (Required): The team the flow belongs to
- `-FlowName` (Required): A name for the flow (e.g., "Customer Portal", "Data Processing")
- `-OutputPath` (Optional): Path where the diagram should be saved (default: .\output)

**Output:**
- Creates an SVG file showing the service flow

### Export-ResourceInventory.ps1

This script exports a comprehensive inventory of all Azure resources.

```powershell
.\Export-ResourceInventory.ps1 -OutputPath "C:\Documentation"
```

**Parameters:**
- `-OutputPath` (Optional): Path where the inventory should be saved (default: .\output)
- `-IncludeSharedResources` (Optional): Include resources tagged as "Shared"

**Output:**
- Creates Excel/CSV files with detailed resource information

## Integration with Documentation Systems

These scripts can be integrated with various documentation systems:

### Azure DevOps Wiki

1. Set up a pipeline to run the scripts regularly
2. Publish the generated SVGs to your Azure DevOps Wiki

```yaml
# azure-pipelines.yml example
steps:
- task: PowerShell@2
  inputs:
    filePath: 'scripts/diagrams/Generate-AllTeamDiagrams.ps1'
    arguments: '-DiscoverTeams'
  displayName: 'Generate Architecture Diagrams'

- task: PowerShell@2
  inputs:
    filePath: 'scripts/diagrams/Export-ResourceInventory.ps1'
  displayName: 'Export Resource Inventory'

- task: PublishBuildArtifacts@1
  inputs:
    pathtoPublish: 'scripts/diagrams/output'
    artifactName: 'architecture-documentation'
  displayName: 'Publish Documentation'
```

### Static Website

1. Generate the diagrams
2. Create HTML pages that include the SVGs
3. Host in Azure Storage with Azure Static Website

### Integration with Existing Documentation

You can embed the generated SVGs in:
- Confluence pages
- SharePoint sites
- Any HTML-based documentation

## Customization

### Modifying Diagram Appearance

The SVG generation is fully customizable. To modify the appearance:

1. Edit the SVG templates in the PowerShell scripts
2. Adjust colors, layouts, and text formats as needed

### Adding New Diagram Types

To create new diagram types:

1. Use the existing scripts as templates
2. Modify the Azure Resource Graph queries to fetch the needed data
3. Create a new SVG template for the diagram format

### Custom Resource Types

The scripts focus on common Azure resource types. To add support for additional resource types:

1. Modify the Azure Resource Graph queries in `Query-TeamResources.ps1`
2. Update the visualization logic in the diagram generation scripts

## Troubleshooting

### Common Issues

- **No diagrams generated**: Ensure your resources have appropriate `Team` tags
- **Missing components in diagrams**: Check if resources have the correct resource types
- **Permission errors**: Ensure you have Reader access to all resources

### Debugging

For detailed debugging:

```powershell
# Enable verbose output
$VerbosePreference = "Continue"
.\Generate-TeamDiagram.ps1 -TeamName "Team1"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

These scripts are provided under the MIT License.
