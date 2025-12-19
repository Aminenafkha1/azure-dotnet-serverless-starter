# Environment Configuration Guide

This guide explains how to configure the serverless starter for different environments (Development, Staging, Production).

## Overview

The solution supports multiple environments through Terraform variables and Function App settings. Each environment should have:
- Separate Azure resources
- Environment-specific configuration
- Appropriate security settings
- Different JWT secrets

## Environment Structure

```
Development (dev)
├── Local Development (Cosmos Emulator)
└── Azure Development (dev resources)

Staging (staging)
└── Azure Staging (staging resources)

Production (prod)
└── Azure Production (prod resources)
```

## Local Development Configuration

### Prerequisites
- Cosmos DB Emulator or Azure Cosmos DB
- .NET 9 SDK
- Azure Functions Core Tools

### Configuration Files

**`src/AuthService/local.settings.json`**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "CosmosDb__EndpointUrl": "https://localhost:8081",
    "CosmosDb__PrimaryKey": "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==",
    "CosmosDb__DatabaseName": "serverless-local",
    "JwtSettings__Secret": "your-local-dev-secret-key-at-least-32-characters",
    "JwtSettings__Issuer": "https://localhost:7071",
    "JwtSettings__Audience": "https://localhost:7072",
    "JwtSettings__ExpirationInMinutes": "60"
  }
}
```

**`src/ProductService/local.settings.json`**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "CosmosDb__EndpointUrl": "https://localhost:8081",
    "CosmosDb__PrimaryKey": "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==",
    "CosmosDb__DatabaseName": "serverless-local",
    "JwtSettings__Secret": "your-local-dev-secret-key-at-least-32-characters",
    "JwtSettings__Issuer": "https://localhost:7071",
    "JwtSettings__Audience": "https://localhost:7072",
    "JwtSettings__ExpirationInMinutes": "60"
  }
}
```

**Note**: `local.settings.json` is excluded from git. Keep your development secrets here.

## Azure Development Environment

### Terraform Configuration

**`infrastructure/terraform.tfvars` (for dev)**
```hcl
project_name = "serverless"
environment  = "dev"
location     = "eastus"

# Optional: Provide custom JWT secret, otherwise auto-generated
# jwt_secret = "your-dev-jwt-secret-at-least-64-characters-long"

jwt_issuer             = "https://func-auth-dev-xxxx.azurewebsites.net"
jwt_audience           = "https://func-product-dev-xxxx.azurewebsites.net"
jwt_expiration_minutes = 60

tags = {
  Project     = "Serverless Starter"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
}
```

### Deployment

```powershell
# Deploy infrastructure
.\scripts\provision-infrastructure.ps1 -Environment dev

# Deploy functions
.\scripts\deploy-all.ps1 -Environment dev
```

### Verification

```powershell
# Test the deployment
$outputs = terraform output -json | ConvertFrom-Json
$authUrl = "https://$($outputs.auth_function_app_default_hostname.value)"
$productUrl = "https://$($outputs.product_function_app_default_hostname.value)"

.\scripts\test-apis.ps1 -BaseUrlAuth $authUrl -BaseUrlProduct $productUrl
```

## Azure Staging Environment

### Purpose
- Pre-production testing
- UAT (User Acceptance Testing)
- Integration testing
- Performance testing

### Terraform Configuration

**`infrastructure/terraform-staging.tfvars`**
```hcl
project_name = "serverless"
environment  = "staging"
location     = "eastus"

jwt_secret             = "your-staging-jwt-secret-unique-and-different-from-dev"
jwt_issuer             = "https://func-auth-staging-xxxx.azurewebsites.net"
jwt_audience           = "https://func-product-staging-xxxx.azurewebsites.net"
jwt_expiration_minutes = 30  # Shorter for staging

tags = {
  Project     = "Serverless Starter"
  Environment = "Staging"
  ManagedBy   = "Terraform"
  Owner       = "QATeam"
}
```

### Deployment

```powershell
# Deploy with staging configuration
terraform apply -var-file="terraform-staging.tfvars"

# Or use script
.\scripts\deploy-all.ps1 -Environment staging
```

### Staging-Specific Settings

- Shorter token expiration (test token refresh scenarios)
- Debug logging enabled
- Test data allowed
- Relaxed rate limiting

## Azure Production Environment

### Purpose
- Live production workloads
- Customer-facing services
- Maximum security and reliability

### Terraform Configuration

**`infrastructure/terraform-prod.tfvars`**
```hcl
project_name = "serverless"
environment  = "prod"
location     = "eastus"  # Consider multi-region for production

# Production requires explicit JWT secret
jwt_secret             = "your-production-jwt-secret-extremely-secure-64-characters-minimum"
jwt_issuer             = "https://api.yourcompany.com"
jwt_audience           = "https://api.yourcompany.com"
jwt_expiration_minutes = 15  # Shorter for security

tags = {
  Project     = "Serverless Starter"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Owner       = "OpsTeam"
  CostCenter  = "Engineering"
}
```

### Production Best Practices

1. **Security**
   ```hcl
   # Use Azure Key Vault for secrets
   # Enable Managed Identity
   # Configure IP restrictions
   # Enable Azure Front Door/API Management
   ```

2. **Monitoring**
   ```powershell
   # Configure alerts in Application Insights
   az monitor metrics alert create \
     --name "high-error-rate" \
     --resource-group $rgName \
     --scopes $functionAppId \
     --condition "avg exceptions > 10"
   ```

3. **Backup and Disaster Recovery**
   ```hcl
   # Configure Cosmos DB backup policy
   backup_policy_type = "Continuous"

   # Consider geo-replication
   geo_location {
     location          = "westus"
     failover_priority = 1
   }
   ```

4. **Deployment**
   ```powershell
   # Use deployment slots
   az functionapp deployment slot create \
     --name $functionAppName \
     --resource-group $rgName \
     --slot staging

   # Deploy to slot first
   # Test
   # Swap to production
   az functionapp deployment slot swap \
     --name $functionAppName \
     --resource-group $rgName \
     --slot staging
   ```

## Configuration by Service

### Auth Service Configuration

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| Token Expiration | 60 min | 30 min | 15 min |
| Password Min Length | 6 | 8 | 8 |
| Logging Level | Debug | Information | Warning |
| CORS | * | Specific domains | Specific domains |

### Product Service Configuration

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| Page Size Max | 100 | 50 | 20 |
| Logging Level | Debug | Information | Warning |
| CORS | * | Specific domains | Specific domains |

## Environment Variables

### Required Variables

All environments need these variables:

```bash
# Cosmos DB
CosmosDb__EndpointUrl
CosmosDb__PrimaryKey
CosmosDb__DatabaseName

# JWT Settings
JwtSettings__Secret
JwtSettings__Issuer
JwtSettings__Audience
JwtSettings__ExpirationInMinutes

# Azure Functions
AzureWebJobsStorage
FUNCTIONS_WORKER_RUNTIME
```

### Optional Variables

```bash
# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING
APPINSIGHTS_INSTRUMENTATIONKEY

# Logging
Logging__LogLevel__Default
Logging__LogLevel__Microsoft
```

## Managing Secrets

### Development
- Store in `local.settings.json` (gitignored)
- Use Cosmos DB Emulator default keys

### Azure Environments

**Option 1: Function App Settings (Current)**
```powershell
az functionapp config appsettings set \
  -g $rgName \
  -n $functionAppName \
  --settings "JwtSettings__Secret=$secret"
```

**Option 2: Azure Key Vault (Recommended for Production)**
```powershell
# Create Key Vault
az keyvault create \
  --name "kv-serverless-prod" \
  --resource-group $rgName \
  --location $location

# Store secret
az keyvault secret set \
  --vault-name "kv-serverless-prod" \
  --name "JwtSecret" \
  --value $secret

# Reference in Function App
az functionapp config appsettings set \
  -g $rgName \
  -n $functionAppName \
  --settings "JwtSettings__Secret=@Microsoft.KeyVault(SecretUri=https://kv-serverless-prod.vault.azure.net/secrets/JwtSecret/)"
```

## Switching Between Environments

### Local to Azure Dev
```powershell
# Ensure local works
.\scripts\run-local.ps1
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"

# Deploy to dev
.\scripts\deploy-all.ps1 -Environment dev
```

### Dev to Staging
```powershell
# Update terraform.tfvars with staging values
# Or use terraform-staging.tfvars
terraform workspace select staging  # If using workspaces
terraform apply -var-file="terraform-staging.tfvars"
```

### Staging to Production
```powershell
# Thorough testing in staging
# Update terraform-prod.tfvars
# Review changes carefully
terraform plan -var-file="terraform-prod.tfvars"
# Apply with extra caution
terraform apply -var-file="terraform-prod.tfvars"
```

## Database Management per Environment

### Local
```
Database: serverless-local
Containers: Users, Products
```

### Dev
```
Database: db-serverless (or serverless-dev)
Containers: Users, Products
```

### Staging
```
Database: db-serverless (or serverless-staging)
Containers: Users, Products
Seed with test data
```

### Production
```
Database: db-serverless (or serverless-prod)
Containers: Users, Products
Enable backups
Configure geo-replication
```

## Cost Optimization by Environment

### Development
- Serverless Cosmos DB (pay-per-request)
- Consumption Function Apps (Y1)
- Basic Application Insights

**Estimated Cost**: $5-20/month

### Staging
- Same as Dev
- Can be deallocated when not testing

**Estimated Cost**: $10-30/month

### Production
- Consider Provisioned Throughput for Cosmos DB (if high, consistent load)
- Consider Premium Function Plan (if cold starts are an issue)
- Standard Application Insights

**Estimated Cost**: Varies based on traffic

## Environment Checklist

### Before Deploying to New Environment

- [ ] Update `terraform.tfvars` with environment-specific values
- [ ] Generate unique JWT secret
- [ ] Update issuer and audience URLs
- [ ] Configure appropriate tags
- [ ] Review security settings
- [ ] Test locally first
- [ ] Plan Terraform changes
- [ ] Backup existing environment (if updating)
- [ ] Deploy infrastructure
- [ ] Deploy function code
- [ ] Run smoke tests
- [ ] Monitor Application Insights
- [ ] Document any issues

### After Deployment

- [ ] Verify all endpoints respond
- [ ] Test authentication flow
- [ ] Test product operations
- [ ] Check Application Insights for errors
- [ ] Review costs in Azure Portal
- [ ] Update documentation
- [ ] Notify team

## Troubleshooting Environment Issues

### Configuration Mismatch
```powershell
# Verify Function App settings
az functionapp config appsettings list \
  -g $rgName \
  -n $functionAppName \
  --query "[].{Name:name, Value:value}" \
  -o table
```

### JWT Issues Between Services
- Ensure JWT secret matches in both services
- Verify issuer and audience URLs
- Check token expiration time

### Cosmos DB Connection Issues
- Verify endpoint URL and key
- Check firewall rules
- Ensure database and containers exist

## Additional Resources

- [Azure Functions Best Practices](https://docs.microsoft.com/azure/azure-functions/functions-best-practices)
- [Cosmos DB Best Practices](https://docs.microsoft.com/azure/cosmos-db/best-practices)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
