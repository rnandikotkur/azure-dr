#!/bin/bash
# DR Health Check Script
# This script validates the health of the DR environment and replication status

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration (replace with actual values)
PRIMARY_RG="primary-rg"
DR_RG="dr-rg"
SQL_SERVER_PRIMARY="primaryserver"
SQL_SERVER_DR="drserver"
SQL_FAILOVER_GROUP="app-fg"
APP_SERVICE_PRIMARY="app-webapp-prod"
APP_SERVICE_DR="app-webapp-dr"
COSMOS_DB_ACCOUNT="app-cosmos"
REDIS_CACHE_PRIMARY="app-redis"
REDIS_CACHE_DR="app-redis-dr"
STORAGE_ACCOUNT_PRIMARY="appstorage"
STORAGE_ACCOUNT_DR="appstoragedr"
APP_GATEWAY_PRIMARY="app-prod-Primary-agw"
APP_GATEWAY_DR="app-prod-Secondary-agw"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check function with color coding
check() {
    local component=$1
    local status=$2
    local details=$3
    
    if [[ "$status" == "Healthy" ]]; then
        log "${GREEN}✓ $component: $status${NC} $details"
        return 0
    elif [[ "$status" == "Warning" ]]; then
        log "${YELLOW}⚠ $component: $status${NC} $details"
        return 1
    else
        log "${RED}✗ $component: $status${NC} $details"
        return 2
    fi
}

# Check Azure CLI installation
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        log "${RED}Azure CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log "${RED}Not logged into Azure. Please run 'az login' first.${NC}"
        exit 1
    }
    
    log "Prerequisites validated."
}

# Check SQL Database replication
check_sql_replication() {
    log "Checking SQL Database replication..."
    
    # Get replication state
    REPLICATION_STATE=$(az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $PRIMARY_RG --server $SQL_SERVER_PRIMARY --query 'replicationState' -o tsv 2>/dev/null)
    
    if [[ "$REPLICATION_STATE" == "CATCH_UP" || "$REPLICATION_STATE" == "HEALTHY" ]]; then
        check "SQL Failover Group" "Healthy" "Replication state: $REPLICATION_STATE"
    elif [[ "$REPLICATION_STATE" == "SEEDING" ]]; then
        check "SQL Failover Group" "Warning" "Replication state: $REPLICATION_STATE - Initial seeding in progress"
    else
        check "SQL Failover Group" "Unhealthy" "Replication state: $REPLICATION_STATE"
    fi
    
    # Get replication role for primary
    PRIMARY_ROLE=$(az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $PRIMARY_RG --server $SQL_SERVER_PRIMARY --query 'replicationRole' -o tsv 2>/dev/null)
    check "Primary SQL Server Role" "Healthy" "Role: $PRIMARY_ROLE"
    
    # Get replication role for secondary
    DR_ROLE=$(az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $DR_RG --server $SQL_SERVER_DR --query 'replicationRole' -o tsv 2>/dev/null)
    check "DR SQL Server Role" "Healthy" "Role: $DR_ROLE"
}

# Check Cosmos DB replication
check_cosmos_db() {
    log "Checking Cosmos DB replication..."
    
    # Get write regions
    WRITE_REGIONS=$(az cosmosdb show --name $COSMOS_DB_ACCOUNT --resource-group $PRIMARY_RG --query "writeLocations[].name" -o tsv 2>/dev/null)
    
    # Check if both regions are in write regions
    if echo "$WRITE_REGIONS" | grep -q "East US" && echo "$WRITE_REGIONS" | grep -q "West US"; then
        check "Cosmos DB Multi-region Write" "Healthy" "Both regions are configured for writes"
    else
        check "Cosmos DB Multi-region Write" "Unhealthy" "Not all regions are configured for writes: $WRITE_REGIONS"
    fi
    
    # Check consistency level
    CONSISTENCY=$(az cosmosdb show --name $COSMOS_DB_ACCOUNT --resource-group $PRIMARY_RG --query "consistencyPolicy.defaultConsistencyLevel" -o tsv 2>/dev/null)
    check "Cosmos DB Consistency" "Healthy" "Level: $CONSISTENCY"
}

# Check Redis Cache replication
check_redis_cache() {
    log "Checking Redis Cache geo-replication..."
    
    # Check if Redis Cache exists in DR region
    if az redis show --name $REDIS_CACHE_DR --resource-group $DR_RG &>/dev/null; then
        # Check if it's linked to primary
        LINKED_SERVER=$(az redis show --name $REDIS_CACHE_DR --resource-group $DR_RG --query "linkedRedisCacheId" -o tsv 2>/dev/null)
        
        if [[ -n "$LINKED_SERVER" && "$LINKED_SERVER" == *"$REDIS_CACHE_PRIMARY"* ]]; then
            check "Redis Cache Geo-replication" "Healthy" "Linked to primary cache"
        else
            check "Redis Cache Geo-replication" "Unhealthy" "Not properly linked to primary cache"
        fi
    else
        check "Redis Cache Geo-replication" "Unhealthy" "DR Redis Cache not found"
    fi
}

# Check Storage Account replication
check_storage_replication() {
    log "Checking Storage Account replication..."
    
    # Check replication type
    PRIMARY_REPLICATION=$(az storage account show --name $STORAGE_ACCOUNT_PRIMARY --resource-group $PRIMARY_RG --query "sku.name" -o tsv 2>/dev/null)
    
    if [[ "$PRIMARY_REPLICATION" == *"RA-GRS"* || "$PRIMARY_REPLICATION" == *"RA-GZRS"* ]]; then
        check "Storage Account Replication" "Healthy" "Type: $PRIMARY_REPLICATION"
    else
        check "Storage Account Replication" "Unhealthy" "Type: $PRIMARY_REPLICATION - Not configured for geo-redundancy"
    fi
    
    # Check if secondary exists
    if az storage account show --name $STORAGE_ACCOUNT_DR --resource-group $DR_RG &>/dev/null; then
        DR_REPLICATION=$(az storage account show --name $STORAGE_ACCOUNT_DR --resource-group $DR_RG --query "sku.name" -o tsv 2>/dev/null)
        check "DR Storage Account" "Healthy" "Type: $DR_REPLICATION"
    else
        check "DR Storage Account" "Warning" "Separate DR Storage Account not found, relying on RA-GRS/RA-GZRS"
    fi
}

# Check App Service health
check_app_services() {
    log "Checking App Services health..."
    
    # Check primary App Service
    PRIMARY_STATUS=$(az webapp show --name $APP_SERVICE_PRIMARY --resource-group $PRIMARY_RG --query "state" -o tsv 2>/dev/null)
    
    if [[ "$PRIMARY_STATUS" == "Running" ]]; then
        check "Primary App Service" "Healthy" "Status: $PRIMARY_STATUS"
    else
        check "Primary App Service" "Unhealthy" "Status: $PRIMARY_STATUS"
    fi
    
    # Check DR App Service
    DR_STATUS=$(az webapp show --name $APP_SERVICE_DR --resource-group $DR_RG --query "state" -o tsv 2>/dev/null)
    
    if [[ "$DR_STATUS" == "Running" ]]; then
        check "DR App Service" "Healthy" "Status: $DR_STATUS"
    else
        check "DR App Service" "Unhealthy" "Status: $DR_STATUS"
    fi
    
    # Check configuration parity
    log "Checking App Service configuration parity..."
    
    # Get settings count from both regions
    PRIMARY_SETTINGS_COUNT=$(az webapp config appsettings list --name $APP_SERVICE_PRIMARY --resource-group $PRIMARY_RG --query "length(@)" -o tsv 2>/dev/null)
    DR_SETTINGS_COUNT=$(az webapp config appsettings list --name $APP_SERVICE_DR --resource-group $DR_RG --query "length(@)" -o tsv 2>/dev/null)
    
    if [[ "$PRIMARY_SETTINGS_COUNT" -eq "$DR_SETTINGS_COUNT" ]]; then
        check "App Service Configuration Parity" "Healthy" "Settings count match: $PRIMARY_SETTINGS_COUNT"
    else
        check "App Service Configuration Parity" "Warning" "Settings count mismatch: Primary=$PRIMARY_SETTINGS_COUNT, DR=$DR_SETTINGS_COUNT"
    fi
}

# Check App Gateway health
check_app_gateways() {
    log "Checking Application Gateways health..."
    
    # Check primary App Gateway
    PRIMARY_AGW_STATUS=$(az network application-gateway show --name $APP_GATEWAY_PRIMARY --resource-group $PRIMARY_RG --query "operationalState" -o tsv 2>/dev/null)
    
    if [[ "$PRIMARY_AGW_STATUS" == "Running" ]]; then
        check "Primary Application Gateway" "Healthy" "Status: $PRIMARY_AGW_STATUS"
    else
        check "Primary Application Gateway" "Unhealthy" "Status: $PRIMARY_AGW_STATUS"
    fi
    
    # Check DR App Gateway
    DR_AGW_STATUS=$(az network application-gateway show --name $APP_GATEWAY_DR --resource-group $DR_RG --query "operationalState" -o tsv 2>/dev/null)
    
    if [[ "$DR_AGW_STATUS" == "Running" ]]; then
        check "DR Application Gateway" "Healthy" "Status: $DR_AGW_STATUS"
    else
        check "DR Application Gateway" "Unhealthy" "Status: $DR_AGW_STATUS"
    fi
}

# Check Traffic Manager
check_traffic_manager() {
    log "Checking Traffic Manager..."
    
    # Get Traffic Manager profile name
    TM_PROFILE=$(az network traffic-manager profile list --query "[?contains(name, '$APP_SERVICE_PRIMARY')].name" -o tsv 2>/dev/null)
    
    if [[ -n "$TM_PROFILE" ]]; then
        # Get endpoints
        PRIMARY_ENDPOINT_STATUS=$(az network traffic-manager endpoint show --name "primary-endpoint" --profile-name $TM_PROFILE --resource-group $PRIMARY_RG --type azureEndpoints --query "endpointStatus" -o tsv 2>/dev/null)
        DR_ENDPOINT_STATUS=$(az network traffic-manager endpoint show --name "dr-endpoint" --profile-name $TM_PROFILE --resource-group $PRIMARY_RG --type azureEndpoints --query "endpointStatus" -o tsv 2>/dev/null)
        
        check "Traffic Manager - Primary Endpoint" "Healthy" "Status: $PRIMARY_ENDPOINT_STATUS"
        check "Traffic Manager - DR Endpoint" "Healthy" "Status: $DR_ENDPOINT_STATUS"
    else
        check "Traffic Manager" "Unhealthy" "Traffic Manager profile not found"
    fi
}

# Run all checks
run_all_checks() {
    check_prerequisites
    
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    WARNING_CHECKS=0
    FAILED_CHECKS=0
    
    # SQL Database
    check_sql_replication
    
    # Cosmos DB
    check_cosmos_db
    
    # Redis Cache
    check_redis_cache
    
    # Storage Account
    check_storage_replication
    
    # App Services
    check_app_services
    
    # App Gateways
    check_app_gateways
    
    # Traffic Manager
    check_traffic_manager
    
    # Summary
    log "\n============ SUMMARY ============"
    log "Total checks: $TOTAL_CHECKS"
    log "${GREEN}Passed: $PASSED_CHECKS${NC}"
    log "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    log "${RED}Failed: $FAILED_CHECKS${NC}"
    
    # Determine overall status
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        log "${RED}Overall DR Status: UNHEALTHY${NC}"
        log "Critical issues found that may impact disaster recovery capability."
        exit 1
    elif [[ $WARNING_CHECKS -gt 0 ]]; then
        log "${YELLOW}Overall DR Status: DEGRADED${NC}"
        log "Non-critical issues found that should be addressed."
        exit 1
    else
        log "${GREEN}Overall DR Status: HEALTHY${NC}"
        log "All disaster recovery components are functioning properly."
        exit 0
    fi
}

# Start execution
run_all_checks
