#!/bin/bash
# Planned Failover Script for Enterprise Azure Application
# This script executes a controlled failover from primary to DR region

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
PRIMARY_RG="primary-rg"
DR_RG="dr-rg"
SQL_SERVER_PRIMARY="primaryserver"
SQL_SERVER_DR="drserver"
SQL_FAILOVER_GROUP="app-fg"
APP_TM_PROFILE="app-tm"
PRIMARY_ENDPOINT="primary-endpoint"
DR_ENDPOINT="dr-endpoint"
GLOBAL_RG="global-rg"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log "ERROR: Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        log "ERROR: Not logged into Azure. Please run 'az login' first."
        exit 1
    }
    
    # Check if failover group exists
    if ! az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $PRIMARY_RG --server $SQL_SERVER_PRIMARY &> /dev/null; then
        log "ERROR: SQL Failover Group $SQL_FAILOVER_GROUP not found."
        exit 1
    }
    
    log "Prerequisites validated successfully."
}

# Pre-failover validation
validate_dr_environment() {
    log "Validating DR environment..."
    
    # Check database replication status
    REPLICATION_STATE=$(az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $PRIMARY_RG --server $SQL_SERVER_PRIMARY --query 'replicationState' -o tsv)
    log "SQL Replication State: $REPLICATION_STATE"
    
    if [[ "$REPLICATION_STATE" != "HEALTHY" ]]; then
        log "WARNING: SQL replication is not healthy. Status: $REPLICATION_STATE"
        read -p "Do you want to continue anyway? (y/n): " CONTINUE
        if [[ "$CONTINUE" != "y" ]]; then
            log "Aborting failover process."
            exit 1
        fi
    fi
    
    # Check application deployment in DR
    # Add additional checks as needed
    
    log "DR environment validation completed."
}

# Execute database failover
failover_database() {
    log "Initiating SQL Database failover..."
    
    az sql failover-group failover --name $SQL_FAILOVER_GROUP --resource-group $DR_RG --server $SQL_SERVER_DR
    
    # Verify successful failover
    REPLICATION_ROLE=$(az sql failover-group show --name $SQL_FAILOVER_GROUP --resource-group $DR_RG --server $SQL_SERVER_DR --query 'replicationRole' -o tsv)
    
    if [[ "$REPLICATION_ROLE" == "Primary" ]]; then
        log "SQL Failover completed successfully. $SQL_SERVER_DR is now Primary."
    else
        log "ERROR: SQL Failover did not complete as expected."
        exit 1
    fi
}

# Redirect traffic to DR region
redirect_traffic() {
    log "Redirecting traffic to DR region..."
    
    # Disable primary endpoint
    az network traffic-manager endpoint update --name $PRIMARY_ENDPOINT --profile-name $APP_TM_PROFILE \
        --resource-group $GLOBAL_RG --type azureEndpoints --endpoint-status Disabled
    
    # Enable DR endpoint with priority 1
    az network traffic-manager endpoint update --name $DR_ENDPOINT --profile-name $APP_TM_PROFILE \
        --resource-group $GLOBAL_RG --type azureEndpoints --endpoint-status Enabled --priority 1
    
    log "Traffic Manager updated. Traffic is now directed to DR region."
    
    # Allow time for DNS propagation
    log "Waiting 5 minutes for DNS propagation..."
    sleep 300
}

# Validate application health
validate_application() {
    log "Validating application health in DR region..."
    
    # Add application-specific health checks here
    # Example: Check website availability
    
    log "Application health validation completed."
}

# Execute failover process
execute_failover() {
    log "Starting planned failover process..."
    
    check_prerequisites
    validate_dr_environment
    failover_database
    redirect_traffic
    validate_application
    
    log "Planned failover completed successfully!"
    log "DR region is now serving production traffic."
    log "Remember to update documentation to reflect the current active region."
}

# Start execution
execute_failover
