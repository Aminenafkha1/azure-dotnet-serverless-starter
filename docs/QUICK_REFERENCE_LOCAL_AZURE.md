# Quick Reference: Local Development with Azure

## 🚀 Quick Start (3 Commands)

```powershell
# 1. Provision Azure resources
cd infrastructure
terraform apply -var-file="terraform-localdev.tfvars"

# 2. Configure local settings
cd ..\scripts
.\setup-local-azure.ps1

# 3. Run locally with Azure connection
.\run-local.ps1
```

## 📋 Complete Workflow

### Initial Setup

```powershell
# Login to Azure
az login
az account set --subscription "Your-Subscription"

# Navigate to project
cd c:\Users\Amine Pc\Desktop\serveless

# Create local dev config
cd infrastructure
cp terraform.tfvars.example terraform-localdev.tfvars

# Edit terraform-localdev.tfvars:
# - environment = "localdev"
# - Other settings as needed

# Initialize and apply
terraform init
terraform apply -var-file="terraform-localdev.tfvars"
```

### Configure Local Functions

```powershell
# Automated setup
cd ..\scripts
.\setup-local-azure.ps1

# This script:
# ✓ Extracts Cosmos DB endpoint
# ✓ Retrieves Cosmos DB key
# ✓ Gets Application Insights connection string
# ✓ Updates both local.settings.json files
```

### Run and Test

```powershell
# Start functions
.\run-local.ps1

# In another terminal, test
cd scripts
.\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

## 🔧 Manual Configuration (If Needed)

### Get Connection Details

```powershell
cd infrastructure

# Get all outputs
terraform output

# Get specific values
$cosmosEndpoint = terraform output -raw cosmosdb_endpoint
$dbName = terraform output -raw cosmosdb_database_name
$rgName = terraform output -raw resource_group_name

# Get Cosmos DB key
$cosmosAccount = az cosmosdb list -g $rgName --query "[0].name" -o tsv
$cosmosKey = az cosmosdb keys list -g $rgName -n $cosmosAccount --query "primaryMasterKey" -o tsv

# Get Application Insights
$appInsights = terraform output -raw application_insights_connection_string
```

### Update local.settings.json Manually

**`src/AuthService/local.settings.json`:**
```json
{
  "Values": {
    "CosmosDb__EndpointUrl": "YOUR_COSMOS_ENDPOINT",
    "CosmosDb__PrimaryKey": "YOUR_COSMOS_KEY",
    "CosmosDb__DatabaseName": "db-serverless",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "YOUR_APP_INSIGHTS_STRING"
  }
}
```

**Same for `src/ProductService/local.settings.json`**

## 📊 Verify Connection

### Check Cosmos DB

```powershell
# List containers
az cosmosdb sql container list \
  --account-name $cosmosAccount \
  --resource-group $rgName \
  --database-name $dbName

# Query data
az cosmosdb sql container query \
  --account-name $cosmosAccount \
  --resource-group $rgName \
  --database-name $dbName \
  --container-name Users \
  --query-text "SELECT * FROM c"
```

### Check Application Insights

```powershell
# View recent logs (after running functions)
az monitor app-insights query \
  --app $appInsightsName \
  --analytics-query "traces | where timestamp > ago(5m) | order by timestamp desc"
```

## 🔄 Daily Development Workflow

```powershell
# Morning: Start functions
cd c:\Users\Amine Pc\Desktop\serveless\scripts
.\run-local.ps1

# Develop and test
# Functions connect to Azure automatically

# View data in Azure Portal
# portal.azure.com → Cosmos DB → Data Explorer

# Evening: Stop functions (Ctrl+C in terminals)
# Azure resources keep running (minimal cost)
```

## 🧹 Cleanup

### Temporary: Stop Functions Only
```powershell
# Just press Ctrl+C in function terminals
# Azure resources remain (data persists)
```

### Full Cleanup: Destroy Azure Resources
```powershell
cd infrastructure
terraform destroy -var-file="terraform-localdev.tfvars"
# Type: yes
```

## 💡 Tips & Tricks

### Switching Between Environments

```powershell
# Use emulator (offline)
# Don't run setup-local-azure.ps1
# Use default local.settings.json with emulator settings

# Use Azure (current setup)
.\setup-local-azure.ps1
.\run-local.ps1
```

### Share Dev Database with Team

Everyone on team:
1. Uses same `terraform-localdev.tfvars`
2. Runs `.\setup-local-azure.ps1`
3. Shares same Cosmos DB
4. Sees each other's data

### View Logs in Real-Time

```powershell
# Terminal 1: Run functions
.\run-local.ps1

# Terminal 2: Stream Application Insights logs
az monitor app-insights query \
  --app $appInsightsName \
  --analytics-query "traces | where timestamp > ago(1m)" \
  --offset 0

# Or use Live Metrics in Azure Portal
```

## 🐛 Troubleshooting

### Can't connect to Cosmos DB?

```powershell
# Add your IP to firewall
$myIp = (Invoke-WebRequest ipinfo.io/ip).Content.Trim()
az cosmosdb firewall-rule create \
  --account-name $cosmosAccount \
  --resource-group $rgName \
  --name "MyLocalDev" \
  --start-ip-address $myIp \
  --end-ip-address $myIp
```

### Configuration out of sync?

```powershell
# Re-run setup
.\setup-local-azure.ps1

# Restart functions
# Ctrl+C in function terminals
.\run-local.ps1
```

### Need fresh database?

```powershell
# Delete all data (careful!)
az cosmosdb sql container delete \
  --account-name $cosmosAccount \
  --resource-group $rgName \
  --database-name $dbName \
  --name Users

# Terraform will recreate on next apply
cd infrastructure
terraform apply -var-file="terraform-localdev.tfvars"
```

## 📁 Key Files

```
serveless/
├── infrastructure/
│   ├── terraform-localdev.tfvars    # Your local dev config
│   └── terraform.tfstate            # Current infrastructure state
├── scripts/
│   ├── setup-local-azure.ps1        # Configure local settings
│   └── run-local.ps1                # Start functions
└── src/
    ├── AuthService/
    │   └── local.settings.json      # Updated by setup script
    └── ProductService/
        └── local.settings.json      # Updated by setup script
```

## 💰 Cost Tracking

```powershell
# View costs for resource group
az consumption usage list \
  --billing-period-name $(date +%Y%m) \
  --query "[?contains(instanceName, 'localdev')]"

# Or check Azure Portal → Cost Management
```

Expected: $1-5/month for low-usage local dev

## 🎯 Common Scenarios

### Scenario: Start fresh each day
```powershell
# Already configured? Just run:
.\run-local.ps1
```

### Scenario: Team member onboarding
```powershell
# New team member:
git clone <repo>
cd infrastructure
terraform init
# Get terraform-localdev.tfvars from team
cd ..\scripts
.\setup-local-azure.ps1
.\run-local.ps1
```

### Scenario: Switch to deployed environment
```powershell
# Stop local functions (Ctrl+C)
# Test against deployed functions instead
cd scripts
.\test-apis.ps1 `
  -BaseUrlAuth "https://func-auth-dev-xxx.azurewebsites.net" `
  -BaseUrlProduct "https://func-product-dev-xxx.azurewebsites.net"
```

## 📚 Additional Resources

- Full Guide: [docs/LOCAL_DEVELOPMENT_WITH_AZURE.md](LOCAL_DEVELOPMENT_WITH_AZURE.md)
- Troubleshooting: [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Architecture: [docs/ARCHITECTURE.md](ARCHITECTURE.md)
