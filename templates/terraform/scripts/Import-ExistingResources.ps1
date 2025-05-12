# Import-ExistingResources.ps1
# Script to import existing Azure resources into Terraform state

# Variables to be set by user
$SubscriptionId = ""
$ResourceGroup = ""
$Region = "northcentralus"
$Environment = "prod"

# Ensure variables are set
if ([string]::IsNullOrEmpty($SubscriptionId) -or [string]::IsNullOrEmpty($ResourceGroup)) {
    Write-Error "Error: Please set SubscriptionId and ResourceGroup variables in this script."
    exit 1
}

# Login to Azure
Write-Host "Logging in to Azure..."
az login
az account set --subscription $SubscriptionId

# Navigate to the correct directory
Set-Location -Path ..\environments\ncus

# Initialize Terraform
Write-Host "Initializing Terraform..."
terraform init

# Import Resource Group
Write-Host "Importing Resource Group..."
terraform import azurerm_resource_group.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup

# Import Virtual Network
Write-Host "Getting VNet information..."
$VNetName = az network vnet list --resource-group $ResourceGroup --query "[0].name" -o tsv

if (-not [string]::IsNullOrEmpty($VNetName)) {
    Write-Host "Importing VNet: $VNetName..."
    terraform import "module.networking.azurerm_virtual_network.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/virtualNetworks/$VNetName
}

# Import App Service Environment
Write-Host "Getting ASE information..."
$AseName = az appservice ase list --resource-group $ResourceGroup --query "[0].name" -o tsv

if (-not [string]::IsNullOrEmpty($AseName)) {
    Write-Host "Importing ASE: $AseName..."
    terraform import module.app_service_environment.azurerm_app_service_environment_v3.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/hostingEnvironments/$AseName
}

# Import App Gateway
Write-Host "Getting Application Gateway information..."
$AppGwName = az network application-gateway list --resource-group $ResourceGroup --query "[0].name" -o tsv

if (-not [string]::IsNullOrEmpty($AppGwName)) {
    Write-Host "Importing Application Gateway: $AppGwName..."
    terraform import module.app_gateway.azurerm_application_gateway.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/applicationGateways/$AppGwName
}

# Import WAF Policy
Write-Host "Getting WAF Policy information..."
$WafPolicyName = az network application-gateway waf-policy list --resource-group $ResourceGroup --query "[0].name" -o tsv

if (-not [string]::IsNullOrEmpty($WafPolicyName)) {
    Write-Host "Importing WAF Policy: $WafPolicyName..."
    terraform import azurerm_web_application_firewall_policy.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/$WafPolicyName
}

# Import App Service Plans
Write-Host "Getting App Service Plans..."
$AppPlans = @(az appservice plan list --resource-group $ResourceGroup --query "[].name" -o tsv)

if ($AppPlans.Count -gt 0) {
    foreach ($PlanName in $AppPlans) {
        # Determine if it's in ASE or public
        $AseId = az appservice plan show --name $PlanName --resource-group $ResourceGroup --query "hostingEnvironmentProfile.id" -o tsv
        
        # Get the OS type
        $Kind = az appservice plan show --name $PlanName --resource-group $ResourceGroup --query "kind" -o tsv
        $IsLinux = $Kind -like "*linux*"
        $OsType = if ($IsLinux) { "Linux" } else { "Windows" }
        
        Write-Host "Importing App Service Plan: $PlanName (${OsType})..."
        
        if (-not [string]::IsNullOrEmpty($AseId) -and $AseId -ne "null") {
            # ASE-based plan
            if ($IsLinux) {
                terraform import module.app_service_plan_linux_ase.azurerm_service_plan.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/serverfarms/$PlanName
            } else {
                terraform import module.app_service_plan_windows_ase.azurerm_service_plan.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/serverfarms/$PlanName
            }
        } else {
            # Public plan
            if ($IsLinux) {
                terraform import module.app_service_plan_linux_public.azurerm_service_plan.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/serverfarms/$PlanName
            } else {
                terraform import module.app_service_plan_windows_public.azurerm_service_plan.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/serverfarms/$PlanName
            }
        }
    }
}

# Import App Services
Write-Host "Getting App Services..."
$WebApps = @(az webapp list --resource-group $ResourceGroup --query "[].name" -o tsv)

if ($WebApps.Count -gt 0) {
    foreach ($WebAppName in $WebApps) {
        # Determine if it's in ASE or public
        $AseId = az webapp show --name $WebAppName --resource-group $ResourceGroup --query "hostingEnvironmentProfile.id" -o tsv
        
        # Get the OS type
        $Kind = az webapp show --name $WebAppName --resource-group $ResourceGroup --query "kind" -o tsv
        $IsLinux = $Kind -like "*linux*"
        $OsType = if ($IsLinux) { "Linux" } else { "Windows" }
        
        Write-Host "Importing App Service: $WebAppName (${OsType})..."
        
        # Extract app name from full name (app-prod-ncus-api -> api)
        $AppName = $WebAppName -replace "app-$Environment-$Region-", ""
        
        if (-not [string]::IsNullOrEmpty($AseId) -and $AseId -ne "null") {
            # ASE-based app
            if ($IsLinux) {
                terraform import "module.app_service_linux_ase[`"$AppName`"].azurerm_linux_web_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$WebAppName
            } else {
                terraform import "module.app_service_windows_ase[`"$AppName`"].azurerm_windows_web_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$WebAppName
            }
        } else {
            # Public app
            if ($IsLinux) {
                terraform import "module.app_service_linux_public[`"$AppName`"].azurerm_linux_web_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$WebAppName
            } else {
                terraform import "module.app_service_windows_public[`"$AppName`"].azurerm_windows_web_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$WebAppName
            }
        }
    }
}

# Import Function Apps
Write-Host "Getting Function Apps..."
$Functions = @(az functionapp list --resource-group $ResourceGroup --query "[].name" -o tsv)

if ($Functions.Count -gt 0) {
    foreach ($FunctionName in $Functions) {
        # Determine if it's in ASE or public
        $AseId = az functionapp show --name $FunctionName --resource-group $ResourceGroup --query "hostingEnvironmentProfile.id" -o tsv
        
        # Get the function app kind/platform (Linux or Windows)
        $Kind = az functionapp show --name $FunctionName --resource-group $ResourceGroup --query "kind" -o tsv
        $IsLinux = $Kind -like "*linux*"
        $OsType = if ($IsLinux) { "Linux" } else { "Windows" }
        
        Write-Host "Importing Function App: $FunctionName (${OsType})..."
        
        # Extract function name from full name (func-prod-ncus-events -> events)
        $FuncName = $FunctionName -replace "func-$Environment-$Region-", ""
        
        if (-not [string]::IsNullOrEmpty($AseId) -and $AseId -ne "null") {
            # ASE-based function
            if ($IsLinux) {
                terraform import "module.function_app_linux_ase[`"$FuncName`"].azurerm_linux_function_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$FunctionName
            } else {
                terraform import "module.function_app_windows_ase[`"$FuncName`"].azurerm_windows_function_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$FunctionName
            }
        } else {
            # Public function
            if ($IsLinux) {
                terraform import "module.function_app_linux_public[`"$FuncName`"].azurerm_linux_function_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$FunctionName
            } else {
                terraform import "module.function_app_windows_public[`"$FuncName`"].azurerm_windows_function_app.main[0]" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$FunctionName
            }
        }
    }
}

# Import Container Apps
Write-Host "Getting Container Apps..."
$ContainerAppEnv = az containerapp env list --resource-group $ResourceGroup --query "[0].name" -o tsv

if (-not [string]::IsNullOrEmpty($ContainerAppEnv)) {
    Write-Host "Importing Container App Environment: $ContainerAppEnv..."
    terraform import module.container_app_environment.azurerm_container_app_environment.main /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.App/managedEnvironments/$ContainerAppEnv
    
    # Import individual Container Apps
    $ContainerApps = @(az containerapp list --resource-group $ResourceGroup --query "[].name" -o tsv)
    
    if ($ContainerApps.Count -gt 0) {
        foreach ($ContainerAppName in $ContainerApps) {
            Write-Host "Importing Container App: $ContainerAppName..."
            $AppName = $ContainerAppName -replace "containerapp-$Environment-$Region-", ""
            terraform import "module.container_app[`"$AppName`"].azurerm_container_app.main" /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.App/containerApps/$ContainerAppName
        }
    }
}

Write-Host "Import complete. Review the output for any errors and validate the imported resources."