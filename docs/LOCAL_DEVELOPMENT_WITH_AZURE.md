# Local Development with Azure Resources

This guide shows how to run Azure Functions locally while connecting to real Azure resources (Cosmos DB, Application Insights, etc.).

## Why Use This Approach?

- Test with production-like data
- Avoid Cosmos DB Emulator limitations
- Test Application Insights integration
- Validate Azure-specific features
- Share development database with team

## Prerequisites

- Azure subscription with resources already deployed
- Azure CLI installed (`az --version` to check)
- .NET 9 SDK
- Azure Functions Core Tools

## 🚀 Quick Start (Copy-Paste Approach)

If you already have Azure resources deployed (via Terraform or manually), just get the connection strings and paste them into your local settings.

### Step 1: Get Connection Strings from Azure

Open PowerShell and run these commands:

```powershell
# Login to Azure (if not already logged in)
az login

# Set your subscription
az account set --subscription "Your-Subscription-Name"

# Set your resource group name (replace with your actual resource group)
$rgName = "rg-serverless-dev-abc123"

# Get Cosmos DB details
$cosmosAccount = az cosmosdb list -g $rgName --query "[0].name" -o tsv
$cosmosEndpoint = az cosmosdb show -g $rgName -n $cosmosAccount --query "documentEndpoint" -o tsv
$cosmosKey = az cosmosdb keys list -g $rgName -n $cosmosAccount --query "primaryMasterKey" -o tsv
$cosmosDb = az cosmosdb sql database list -g $rgName -n $cosmosAccount --query "[0].name" -o tsv

# Get Application Insights connection string
$appInsights = az monitor app-insights component list -g $rgName --query "[0].name" -o tsv
$appInsightsConnection = az monitor app-insights component show -g $rgName -a $appInsights --query "connectionString" -o tsv

# Display everything
Write-Host "`n=== COPY THESE VALUES ===" -ForegroundColor Green
Write-Host "Cosmos DB Endpoint: $cosmosEndpoint"
Write-Host "Cosmos DB Key: $cosmosKey"
Write-Host "Database Name: $cosmosDb"
Write-Host "App Insights: $appInsightsConnection"
```

**Copy the output values!**

### Step 2: Paste into local.settings.json

Open `src/AuthService/local.settings.json` and paste your values:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",

    "CosmosDb__EndpointUrl": "PASTE_YOUR_COSMOS_ENDPOINT_HERE",
    "CosmosDb__PrimaryKey": "PASTE_YOUR_COSMOS_KEY_HERE",
    "CosmosDb__DatabaseName": "PASTE_YOUR_DATABASE_NAME_HERE",

    "JwtSettings__Secret": "your-local-dev-secret-key-at-least-32-characters",
    "JwtSettings__Issuer": "https://localhost:7071",
    "JwtSettings__Audience": "https://localhost:7072",
    "JwtSettings__ExpirationInMinutes": "60",

    "APPLICATIONINSIGHTS_CONNECTION_STRING": "PASTE_YOUR_APP_INSIGHTS_CONNECTION_HERE"
  }
}
```

Do the same for `src/ProductService/local.settings.json`.

### Step 3: Run Locally

```powershell
# Start both services
cd scripts
.\run-local.ps1
```

That's it! Your local functions are now connected to Azure.

---

## Alternative: One-Line Commands

Get each value individually:

```powershell
# Cosmos DB Endpoint
az cosmosdb show -g YOUR_RESOURCE_GROUP -n YOUR_COSMOS_ACCOUNT --query "documentEndpoint" -o tsv

# Cosmos DB Key
az cosmosdb keys list -g YOUR_RESOURCE_GROUP -n YOUR_COSMOS_ACCOUNT --query "primaryMasterKey" -o tsv

# App Insights Connection String
az monitor app-insights component show -g YOUR_RESOURCE_GROUP -a YOUR_APP_INSIGHTS --query "connectionString" -o tsv
```

---

## 📋 Complete Step-by-Step Example

### If You Already Have Resources Deployed

**Step 1:** Open PowerShell and run:

```powershell
# Replace with your actual resource group name
$rgName = "rg-serverless-dev-abc123"

# Get everything in one go
$cosmosAccount = (az cosmosdb list -g $rgName --query "[0].name" -o tsv)
Write-Host "Cosmos Account: $cosmosAccount"

$cosmosEndpoint = (az cosmosdb show -g $rgName -n $cosmosAccount --query "documentEndpoint" -o tsv)
Write-Host "Endpoint: $cosmosEndpoint"

$cosmosKey = (az cosmosdb keys list -g $rgName -n $cosmosAccount --query "primaryMasterKey" -o tsv)
Write-Host "Key: $cosmosKey"
```

**Step 2:** Copy the values from the output.

**Step 3:** Open `src\AuthService\local.settings.json` in VS Code or any text editor.

**Step 4:** Replace the placeholder values:

```json
{
  "Values": {
    "CosmosDb__EndpointUrl": "https://cosmos-serverless-xxx.documents.azure.com:443/",
    "CosmosDb__PrimaryKey": "your-long-key-from-step-1",
    "CosmosDb__DatabaseName": "db-serverless"
  }
}
```

**Step 5:** Do the same for `src\ProductService\local.settings.json`.

**Step 6:** Run locally:

```powershell
cd src\AuthService
func start --port 7071
```

In another terminal:

```powershell
cd src\ProductService
func start --port 7072
```

**Step 7:** Test:

```powershell
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

---

## 🎯 If You Need to Deploy Resources First

### Step 1: Provision Azure Resources with Terraform

```powershell
# Navigate to infrastructure directory
cd infrastructure

# Create terraform.tfvars for local-dev environment
# Copy and edit the example
cp terraform.tfvars.example terraform-localdev.tfvars
```

**Edit `terraform-localdev.tfvars`:**
```hcl
project_name = "serverless"
environment  = "localdev"  # Use 'localdev' to distinguish from deployed environments
location     = "eastus"

# These won't be used since functions run locally
jwt_issuer             = "https://localhost:7071"
jwt_audience           = "https://localhost:7072"
jwt_expiration_minutes = 60

tags = {
  Project     = "Serverless Starter"
  Environment = "LocalDev"
  ManagedBy   = "Terraform"
  Purpose     = "Local development with cloud resources"
}
```

```powershell
# Login to Azure
az login
az account set --subscription "Your-Subscription-Name"

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan -var-file="terraform-localdev.tfvars"

# Create the resources
terraform apply -var-file="terraform-localdev.tfvars"
```

This creates:
- ✅ Cosmos DB account with Users and Products containers
- ✅ Application Insights
- ✅ Storage Account
- ✅ Function Apps (empty, won't be used for local dev)

### Step 2: Extract Connection Strings

After Terraform completes, get the connection details:

```powershell
# Get all outputs
terraform output -json | ConvertFrom-Json

# Or get specific values
$cosmosEndpoint = terraform output -raw cosmosdb_endpoint
$cosmosDbName = terraform output -raw cosmosdb_database_name
$appInsightsConnectionString = terraform output -raw application_insights_connection_string

Write-Host "Cosmos DB Endpoint: $cosmosEndpoint"
Write-Host "Database Name: $cosmosDbName"
Write-Host "App Insights: $appInsightsConnectionString"
```

**Get Cosmos DB Primary Key:**
```powershell
$rgName = terraform output -raw resource_group_name
$cosmosAccountName = (az cosmosdb list -g $rgName --query "[0].name" -o tsv)
$cosmosKey = (az cosmosdb keys list -g $rgName -n $cosmosAccountName --query "primaryMasterKey" -o tsv)

Write-Host "Cosmos DB Key: $cosmosKey"
```

### Step 3: Update Local Settings

**Update `src/AuthService/local.settings.json`:**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",

    "CosmosDb__EndpointUrl": "https://cosmos-serverless-localdev-xxxx.documents.azure.com:443/",
    "CosmosDb__PrimaryKey": "your-cosmos-primary-key-from-step-2",
    "CosmosDb__DatabaseName": "db-serverless",

    "JwtSettings__Secret": "your-local-dev-secret-key-at-least-32-characters",
    "JwtSettings__Issuer": "https://localhost:7071",
    "JwtSettings__Audience": "https://localhost:7072",
    "JwtSettings__ExpirationInMinutes": "60",

    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=xxxx;IngestionEndpoint=https://..."
  }
}
```

**Update `src/ProductService/local.settings.json`:**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",

    "CosmosDb__EndpointUrl": "https://cosmos-serverless-localdev-xxxx.documents.azure.com:443/",
    "CosmosDb__PrimaryKey": "your-cosmos-primary-key-from-step-2",
    "CosmosDb__DatabaseName": "db-serverless",

    "JwtSettings__Secret": "your-local-dev-secret-key-at-least-32-characters",
    "JwtSettings__Issuer": "https://localhost:7071",
    "JwtSettings__Audience": "https://localhost:7072",
    "JwtSettings__ExpirationInMinutes": "60",

    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=xxxx;IngestionEndpoint=https://..."
  }
}
```

### Step 4: Run Functions Locally

```powershell
# Terminal 1 - Auth Service
cd src\AuthService
func start --port 7071

# Terminal 2 - Product Service
cd src\ProductService
func start --port 7072
```

**Or use the helper script (after updating local.settings.json):**
```powershell
.\scripts\run-local.ps1
```

### Step 5: Test Your Setup

```powershell
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

## Automated Script for Setup

Create a helper script to automate the configuration:

**`scripts/setup-local-azure.ps1`:**
```powershell
#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "localdev"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up local development with Azure resources..." -ForegroundColor Cyan

# Step 1: Check if Terraform has been applied
cd infrastructure

if (-not (Test-Path "terraform.tfstate")) {
    Write-Host "Terraform state not found. Please run terraform apply first." -ForegroundColor Red
    exit 1
}

# Step 2: Extract outputs
Write-Host "`nExtracting Terraform outputs..." -ForegroundColor Yellow
$outputs = terraform output -json | ConvertFrom-Json

$cosmosEndpoint = $outputs.cosmosdb_endpoint.value
$cosmosDbName = $outputs.cosmosdb_database_name.value
$appInsightsConnectionString = $outputs.application_insights_connection_string.value
$rgName = $outputs.resource_group_name.value

Write-Host "Resource Group: $rgName" -ForegroundColor Gray
Write-Host "Cosmos Endpoint: $cosmosEndpoint" -ForegroundColor Gray
Write-Host "Database: $cosmosDbName" -ForegroundColor Gray

# Step 3: Get Cosmos DB key
Write-Host "`nRetrieving Cosmos DB key..." -ForegroundColor Yellow
$cosmosAccountName = (az cosmosdb list -g $rgName --query "[0].name" -o tsv)
$cosmosKey = (az cosmosdb keys list -g $rgName -n $cosmosAccountName --query "primaryMasterKey" -o tsv)

# Step 4: Update local.settings.json files
Write-Host "`nUpdating local.settings.json files..." -ForegroundColor Yellow

$authSettingsPath = "..\src\AuthService\local.settings.json"
$productSettingsPath = "..\src\ProductService\local.settings.json"

# Read existing settings
$authSettings = Get-Content $authSettingsPath | ConvertFrom-Json
$productSettings = Get-Content $productSettingsPath | ConvertFrom-Json

# Update Cosmos DB settings
$authSettings.Values.'CosmosDb__EndpointUrl' = $cosmosEndpoint
$authSettings.Values.'CosmosDb__PrimaryKey' = $cosmosKey
$authSettings.Values.'CosmosDb__DatabaseName' = $cosmosDbName
$authSettings.Values.'APPLICATIONINSIGHTS_CONNECTION_STRING' = $appInsightsConnectionString

$productSettings.Values.'CosmosDb__EndpointUrl' = $cosmosEndpoint
$productSettings.Values.'CosmosDb__PrimaryKey' = $cosmosKey
$productSettings.Values.'CosmosDb__DatabaseName' = $cosmosDbName
$productSettings.Values.'APPLICATIONINSIGHTS_CONNECTION_STRING' = $appInsightsConnectionString

# Save updated settings
$authSettings | ConvertTo-Json -Depth 10 | Set-Content $authSettingsPath
$productSettings | ConvertTo-Json -Depth 10 | Set-Content $productSettingsPath

Write-Host "`n✅ Configuration complete!" -ForegroundColor Green
Write-Host "`nYou can now run:" -ForegroundColor Cyan
Write-Host "  .\scripts\run-local.ps1" -ForegroundColor White
Write-Host "`nTo test APIs:" -ForegroundColor Cyan
Write-Host "  .\scripts\test-apis.ps1 -BaseUrlAuth 'http://localhost:7071' -BaseUrlProduct 'http://localhost:7072'" -ForegroundColor White

cd ..
```

**Make it executable and run:**
```powershell
# After terraform apply
.\scripts\setup-local-azure.ps1
```

## Verifying the Connection

### Check Cosmos DB Connection

```powershell
# View data in Azure Portal
az cosmosdb sql database show \
  --account-name $cosmosAccountName \
  --resource-group $rgName \
  --name $cosmosDbName

# List containers
az cosmosdb sql container list \
  --account-name $cosmosAccountName \
  --resource-group $rgName \
  --database-name $cosmosDbName
```

### Check Application Insights

After running your functions locally:

```powershell
# View recent traces
az monitor app-insights query \
  --app $appInsightsName \
  --analytics-query "traces | where timestamp > ago(5m) | order by timestamp desc | take 20"

# View requests
az monitor app-insights query \
  --app $appInsightsName \
  --analytics-query "requests | where timestamp > ago(5m) | order by timestamp desc"
```

Or visit Azure Portal → Application Insights → Transaction search

## Complete Workflow Example

```powershell
# 1. Provision Azure resources
cd infrastructure
terraform init
terraform apply -var-file="terraform-localdev.tfvars"

# 2. Configure local settings
cd ..
.\scripts\setup-local-azure.ps1

# 3. Run functions locally
.\scripts\run-local.ps1

# 4. Test in another terminal
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"

# 5. View data in Azure Portal or CLI
az cosmosdb sql container query \
  --account-name $cosmosAccountName \
  --resource-group $rgName \
  --database-name $cosmosDbName \
  --container-name Users \
  --query-text "SELECT * FROM c"
```

## Benefits of This Approach

✅ **Real Azure Environment**: Test with actual Cosmos DB (not emulator)
✅ **Application Insights**: See telemetry in real-time
✅ **Team Collaboration**: Share development database
✅ **Production Parity**: Closer to production environment
✅ **No Emulator Issues**: Avoid Cosmos DB Emulator limitations
✅ **Cloud Features**: Test geo-replication, backup, etc.

## Cost Considerations

- **Cosmos DB Serverless**: Pay only for operations (~$0.25/million RUs)
- **Application Insights**: 5GB/month free
- **Storage**: Minimal cost for function storage

**Estimated cost for local dev**: $1-5/month (very low usage)

## Cleanup

When you're done with local development resources:

```powershell
cd infrastructure

# Destroy all resources
terraform destroy -var-file="terraform-localdev.tfvars"

# Confirm: yes
```

## Troubleshooting

### Issue: Can't connect to Cosmos DB

**Solution:**
```powershell
# Check if Cosmos DB allows your IP
az cosmosdb firewall-rule list \
  --account-name $cosmosAccountName \
  --resource-group $rgName

# Add your IP if needed
$myIp = (Invoke-WebRequest -Uri "https://api.ipify.org").Content
az cosmosdb firewall-rule create \
  --account-name $cosmosAccountName \
  --resource-group $rgName \
  --name "LocalDev" \
  --start-ip-address $myIp \
  --end-ip-address $myIp
```

### Issue: SSL/TLS errors

**Solution:**
Ensure you're using HTTPS endpoint from Cosmos DB (not HTTP)

### Issue: Application Insights not showing data

**Solution:**
- Wait 1-2 minutes for data to appear
- Verify connection string is correct
- Check function logs for errors

## Best Practices

1. **Use separate 'localdev' environment** to avoid conflicts with deployed environments
2. **Never commit local.settings.json** with real Azure credentials
3. **Use Azure CLI authentication** when possible
4. **Clean up resources** when not actively developing
5. **Monitor costs** in Azure Portal
6. **Use resource tags** to identify local dev resources

## Alternative: Use Only Cosmos DB from Azure

If you want to minimize costs, you can use only Cosmos DB from Azure and keep Application Insights local:

```json
{
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "CosmosDb__EndpointUrl": "https://cosmos-serverless-localdev-xxxx.documents.azure.com:443/",
    "CosmosDb__PrimaryKey": "your-cosmos-key",
    "CosmosDb__DatabaseName": "db-serverless"
    // Remove Application Insights connection string for local-only logging
  }
}
```

## Summary

This approach gives you:
- ☁️ Cloud resources for realistic testing
- 💻 Local debugging and development speed
- 💰 Minimal costs
- 🔄 Easy switching between environments
- 👥 Team collaboration on shared dev database

Now you can develop locally with the confidence that your functions work exactly as they will in Azure!
