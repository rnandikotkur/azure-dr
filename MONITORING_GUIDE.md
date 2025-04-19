# Azure Enterprise Application Disaster Recovery
## Monitoring Guide

This document outlines comprehensive monitoring strategies to ensure the disaster recovery solution remains effective and ready for activation when needed.

## Table of Contents

1. [Monitoring Philosophy](#monitoring-philosophy)
2. [Key Metrics](#key-metrics)
3. [Monitoring Infrastructure](#monitoring-infrastructure)
4. [Alert Configuration](#alert-configuration)
5. [Dashboard Setup](#dashboard-setup)
6. [Reporting Framework](#reporting-framework)
7. [Maintenance Procedures](#maintenance-procedures)

## Monitoring Philosophy

Effective DR monitoring is built on these principles:

1. **Continuous Validation**: DR readiness must be continuously monitored, not just during tests.
2. **Early Warning**: Issues affecting DR capability should be detected before they impact recovery.
3. **Cross-Region Visibility**: Monitoring must span both primary and DR environments.
4. **Business Context**: Technical metrics should be translated into business impact.
5. **Actionable Insights**: Alerts should provide clear guidance on remediation steps.

## Key Metrics

### Replication Health Metrics

| Metric | Description | Target | Warning Threshold | Critical Threshold |
|--------|-------------|--------|-------------------|---------------------|
| SQL Replication Lag | Time delay between primary and secondary | < 5 sec | > 30 sec | > 2 min |
| Storage GRS Lag | Last sync time for geo-redundant storage | < 15 min | > 30 min | > 60 min |
| Cosmos DB Replication | Multi-region write synchronization status | 100% | < 99.9% | < 99% |
| Redis Cache Sync | Premium tier geo-replication status | Connected | Warning | Disconnected |
| Configuration Drift | Difference between primary and DR configuration | 0 items | 1-5 items | > 5 items |

### Recovery Time Metrics

| Metric | Description | Target | Warning Threshold | Critical Threshold |
|--------|-------------|--------|-------------------|---------------------|
| Database Failover Time | Time to complete SQL failover | < 30 sec | > 1 min | > 5 min |
| Traffic Shift Time | Time for Traffic Manager to route to DR | < 1 min | > 3 min | > 10 min |
| App Warmup Time | Time for app services to reach normal performance | < 3 min | > 5 min | > 15 min |
| Full Recovery Time | End-to-end recovery time in latest test | < 30 min | > 45 min | > 60 min |
| Data Loss Window | Measured RPO in latest test | < 5 sec | > 30 sec | > 5 min |

### DR Environment Health Metrics

| Metric | Description | Target | Warning Threshold | Critical Threshold |
|--------|-------------|--------|-------------------|---------------------|
| DR Resource Uptime | Availability of key DR components | 99.9% | < 99.5% | < 99% |
| DR Environment Cost | Monthly cost of DR environment | Within budget | 10% over | 20% over |
| Last Successful Test | Days since last successful DR test | < 90 days | > 120 days | > 180 days |
| Test Success Rate | Percentage of successful DR tests | 100% | < 90% | < 80% |
| DR Runbook Currency | Days since DR procedures updated | < 90 days | > 120 days | > 180 days |

## Monitoring Infrastructure

### Azure Monitor Configuration

1. **Resource Health Alerts**:
   ```bash
   # Create Resource Health alert for critical DR components
   az monitor activity-log alert create --name DR-Resource-Health \
     --resource-group monitoring-rg --scopes "/subscriptions/subId" \
     --condition category=ResourceHealth and level=Critical \
     --action-group dr-critical-actiongroup
   ```

2. **Cross-Region Metrics**:
   - Configure consolidated metrics dashboards
   - Implement custom metrics for DR-specific statuses
   - Create availability tests for DR environment components

3. **Log Analytics Workspace**:
   - Centralize logs from both primary and DR regions
   - Implement custom KQL queries for DR health status
   - Set up workbooks for DR readiness reporting

### Application Insights

1. **Availability Tests**:
   ```bash
   # PowerShell example for creating availability test
   New-AzApplicationInsightsWebTest -Name "DR-WebApp-Test" `
     -ResourceGroupName "monitoring-rg" `
     -Location "East US 2" `
     -ApplicationInsightsComponent $appInsightsComponent `
     -Kind "ping" `
     -Frequency 300 `
     -WebTest "<WebTest...>" `
     -RetryEnabled $true `
     -Locations "us-fl-mia-edge,us-tx-sn1-azr,us-il-ch1-azr"
   ```

2. **Custom Telemetry**:
   - Implement DR readiness health checks in application
   - Track dependency availability across regions
   - Measure cross-region latency

3. **Application Map**:
   - Configure unified application map
   - Visualize dependencies between regions
   - Identify critical path components

### DynaTrace Integration

1. **OneAgent Deployment**:
   - Install on all critical components in both regions
   - Configure unified monitoring
   - Implement service flow visualization

2. **Custom Metrics**:
   - Create DR readiness metrics
   - Configure business impact measures
   - Set up synthetic monitors for DR paths

3. **Problem Detection**:
   - Tune problem patterns for DR components
   - Configure Davis AI for anomaly detection
   - Create DR impact analysis dashboards

## Alert Configuration

### Critical Alerts

| Alert | Trigger | Severity | Response Time | Notification Channel |
|-------|---------|----------|---------------|----------------------|
| Replication Failure | SQL/Cosmos replication broken | Critical | 15 min | Phone + Email + Teams |
| DR Component Down | Key DR service unavailable | Critical | 30 min | Email + Teams |
| Configuration Drift | Significant drift detected | High | 4 hours | Email |
| Test Failure | DR test fails critical criteria | High | 8 hours | Email |
| Replication Lag | RPO threshold exceeded | Medium | 24 hours | Email |

### Alert Action Configuration

1. **Action Groups**:
   ```bash
   # Create action group for critical DR alerts
   az monitor action-group create --name dr-critical-actiongroup \
     --resource-group monitoring-rg \
     --short-name drcrit \
     --email-receiver name=dradmin email=dradmin@example.com \
     --sms-receiver name=droncall phone=+15555555555 \
     --webhook-receiver name=drwebhook uri=https://example.com/webhook
   ```

2. **Escalation Paths**:
   - First level: DR operations team (immediate)
   - Second level: Technology leadership (30 min)
   - Third level: Executive notification (2 hours)

3. **Runbook Integration**:
   - Auto-remediation for common issues
   - Documentation links in alert emails
   - Teams channel integration with playbook links

### Alert Testing

1. **Validation Process**:
   - Test each alert at implementation
   - Verify notification delivery
   - Confirm runbook effectiveness 

2. **Alert Maintenance**:
   - Review alert effectiveness quarterly
   - Tune thresholds based on operational data
   - Update notification paths as teams change

## Dashboard Setup

### Executive DR Dashboard

1. **Components**:
   - Overall DR readiness status (single indicator)
   - Days since last successful test
   - Current RPO/RTO achievement
   - Cost of DR environment
   - Significant incidents in last 30 days

2. **Implementation**:
   ```bash
   # Create Azure Dashboard
   az portal dashboard create --name ExecDRDashboard \
     --resource-group monitoring-rg \
     --location eastus \
     --dashboard-path executiveDashboard.json
   ```

### Operations DR Dashboard

1. **Components**:
   - Detailed replication status for all components
   - Configuration drift detection
   - Alert history
   - Test results and metrics
   - Environment health by component

2. **Resource Organization**:
   - Group by criticality tier
   - Highlight components affecting RPO/RTO
   - Show maintenance schedule
   - Display pending changes

### Technical DR Dashboard

1. **Components**:
   - Detailed logs and diagnostics
   - Performance metrics for DR components
   - Network connectivity status
   - Security and compliance status
   - Automation execution history

2. **Drill-Down Capability**:
   - Component-level detail views
   - Historical trend analysis
   - Test result comparisons
   - Configuration version tracking

## Reporting Framework

### Daily DR Health Report

1. **Content**:
   - Overall DR readiness status
   - Key metrics vs thresholds
   - Notable incidents or changes
   - Pending actions or tests

2. **Distribution**:
   - DR operations team
   - Application support teams
   - Infrastructure teams

3. **Automation**:
   ```bash
   # Example PowerShell snippet for automated report generation
   $report = New-Object PSObject -Property @{
     Date = Get-Date
     OverallStatus = "Green" # Dynamic based on metrics
     ReplicationHealth = "Normal"
     PendingActions = @("Quarterly test due in 15 days")
   }
   Send-MailMessage -To dradmin@example.com -From reporting@example.com `
     -Subject "Daily DR Health Report" -Body ($report | ConvertTo-Html)
   ```

### Monthly DR Performance Report

1. **Content**:
   - Trend analysis of key metrics
   - Test results and learnings
   - Cost analysis and optimization
   - Improvement recommendations

2. **Distribution**:
   - Technology leadership
   - Business continuity team
   - Application owners

3. **Review Process**:
   - Monthly review meeting
   - Action item tracking
   - Improvement implementation timing

### Quarterly Business Review

1. **Content**:
   - Business impact analysis
   - RPO/RTO achievement vs requirements
   - Cost vs value assessment
   - Strategic recommendations

2. **Distribution**:
   - Executive leadership
   - Business unit owners
   - Risk management team

3. **Outcome Tracking**:
   - Business requirement updates
   - Budget adjustments
   - Policy or procedure changes

## Maintenance Procedures

### Monitoring System Maintenance

1. **Alert Tuning**:
   - Review alert frequency quarterly
   - Adjust thresholds based on operational patterns
   - Retire redundant alerts
   - Create new alerts for emerging patterns

2. **Dashboard Updates**:
   - Review dashboard effectiveness monthly
   - Update visualizations based on feedback
   - Add new metrics as DR solution evolves
   - Archive outdated information

3. **Log Management**:
   - Configure appropriate retention periods
   - Implement log analytics workspace optimization
   - Set up log export for long-term analysis
   - Review query performance periodically

### Documentation Updates

1. **Update Triggers**:
   - After DR tests or exercises
   - When alert thresholds change
   - When monitoring infrastructure changes
   - When business requirements change

2. **Version Control**:
   - Maintain documentation in Git repository
   - Require peer review for changes
   - Tag versions associated with tests
   - Maintain change history

3. **Knowledge Sharing**:
   - Conduct regular monitoring overview sessions
   - Train new team members on monitoring tools
   - Document common troubleshooting procedures
   - Create monitoring system architecture diagrams

## Appendices

### A. Monitoring Tool Reference

1. **Azure Monitor**:
   - [Documentation Link](https://docs.microsoft.com/en-us/azure/azure-monitor/)
   - Primary tool for infrastructure monitoring
   - Used for resource health and metrics across regions

2. **Application Insights**:
   - [Documentation Link](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
   - Application performance monitoring
   - End-to-end transaction tracking

3. **DynaTrace**:
   - [Documentation Link](https://www.dynatrace.com/support/help/)
   - Advanced application performance monitoring
   - AI-powered problem detection

### B. KQL Query Examples

1. **Replication Health Check**:
   ```kql
   // SQL Database replication lag
   AzureDiagnostics
   | where Category == "SQLSecurityAuditEvents"
   | where TimeGenerated > ago(1h)
   | summarize ReplicationLag=max(todouble(ResponseTime)) by _ResourceId
   | where ReplicationLag > 30
   ```

2. **Configuration Drift Detection**:
   ```kql
   // Compare app settings between environments
   let primary = AppSettings
   | where ResourceGroup == "primary-rg"
   | project Setting, PrimaryValue=Value;
   let dr = AppSettings
   | where ResourceGroup == "dr-rg"
   | project Setting, DRValue=Value;
   primary | join kind=fullouter dr on Setting
   | where PrimaryValue != DRValue or isempty(PrimaryValue) or isempty(DRValue)
   ```

3. **DR Test Result Tracking**:
   ```kql
   // DR test results over time
   DRTestResults
   | where TimeGenerated > ago(365d)
   | summarize TestCount=count(), SuccessCount=countif(Result == "Success") by bin(TimeGenerated, 7d)
   | extend SuccessRate = SuccessCount*100.0/TestCount
   | render timechart
   ```

### C. Alert Template Examples

1. **SQL Replication Alert**:
   ```json
   {
     "type": "Microsoft.Insights/metricAlerts",
     "name": "SQL-Replication-Lag",
     "location": "global",
     "properties": {
       "severity": 1,
       "enabled": true,
       "scopes": ["/subscriptions/subId/resourceGroups/primary-rg/providers/..."],
       "evaluationFrequency": "PT5M",
       "windowSize": "PT15M",
       "criteria": {
         "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
         "allOf": [
           {
             "metricName": "replication_lag",
             "operator": "GreaterThan",
             "threshold": 300,
             "timeAggregation": "Average"
           }
         ]
       },
       "actions": [
         {
           "actionGroupId": "/subscriptions/subId/resourcegroups/monitoring-rg/providers/microsoft.insights/actiongroups/dr-critical-actiongroup"
         }
       ]
     }
   }
   ```

2. **DR Component Availability Alert**:
   ```json
   {
     "type": "Microsoft.Insights/webtests",
     "name": "DR-WebApp-Availability",
     "location": "eastus2",
     "properties": {
       "SyntheticMonitorId": "DR-WebApp-Availability",
       "Name": "DR Web Application",
       "Description": "Validates DR web application availability",
       "Enabled": true,
       "Frequency": 300,
       "Timeout": 120,
       "Kind": "ping",
       "RetryEnabled": true,
       "Locations": [
         {"Id": "us-fl-mia-edge"},
         {"Id": "us-va-ash-azr"},
         {"Id": "us-tx-sn1-azr"}
       ],
       "Configuration": {
         "WebTest": "..."
       }
     }
   }
   ```

### D. Example Dashboard Templates

1. **Executive Dashboard JSON Template**
2. **Operations Dashboard JSON Template**
3. **Technical Dashboard JSON Template**
