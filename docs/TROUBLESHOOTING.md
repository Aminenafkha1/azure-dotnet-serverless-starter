# Troubleshooting Guide

Common issues and their solutions when working with this serverless starter.

## Build & Compilation Issues

### Issue: "SDK not found" Error

**Error:**
```
error MSB4236: The SDK 'Microsoft.NET.Sdk' specified could not be found.
```

**Solution:**
- Ensure .NET 9 SDK is installed: `dotnet --list-sdks`
- Install from: https://dotnet.microsoft.com/download/dotnet/9.0
- Verify `global.json` specifies the correct SDK version

### Issue: Package Restore Failures

**Error:**
```
error NU1101: Unable to find package...
```

**Solution:**
```powershell
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore packages
dotnet restore
```

## Local Development Issues

### Issue: Functions Won't Start

**Error:**
```
Azure Functions Core Tools not found
```

**Solution:**
```powershell
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Or use Chocolatey (Windows)
choco install azure-functions-core-tools-4
```

### Issue: Port Already in Use

**Error:**
```
Port 7071 is already in use
```

**Solution:**
```powershell
# Find process using the port
netstat -ano | findstr :7071

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or use a different port
func start --port 7073
```

### Issue: Cosmos DB Emulator Connection Failed

**Error:**
```
Request timeout while connecting to Cosmos DB
```

**Solution:**
- Ensure Cosmos DB Emulator is running
- Check emulator is accessible at: https://localhost:8081/_explorer/index.html
- Reset emulator data: Right-click tray icon → Reset Data
- Check Windows Firewall isn't blocking port 8081

### Issue: "The SSL connection could not be established"

**Solution:**
For Cosmos DB Emulator, add this to `local.settings.json`:
```json
{
  "Values": {
    "CosmosDb__DisableSslVerification": "true"
  }
}
```

Or export the emulator certificate:
```powershell
# Export certificate from Cosmos DB Emulator
# Go to emulator → Export SSL Certificate
# Install to Trusted Root Certification Authorities
```

## Terraform Issues

### Issue: Authentication Failed

**Error:**
```
Error: building AzureRM Client: obtain subscription() from Azure CLI...
```

**Solution:**
```powershell
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

### Issue: Resource Already Exists

**Error:**
```
Error: A resource with the ID already exists
```

**Solution:**
```powershell
# Import existing resource
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-name

# Or use a different resource suffix
# Edit terraform.tfvars and change project_name or environment
```

### Issue: State Lock

**Error:**
```
Error: Error acquiring the state lock
```

**Solution:**
```powershell
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or delete lock from storage if using remote backend
```

### Issue: Provider Version Conflict

**Error:**
```
Error: Failed to query available provider packages
```

**Solution:**
```powershell
# Remove lock file and re-initialize
Remove-Item .terraform.lock.hcl
terraform init -upgrade
```

## Deployment Issues

### Issue: Function App Deployment Failed

**Error:**
```
Zip deployment failed
```

**Solution:**
```powershell
# Ensure function app is running
az functionapp show -g <resource-group> -n <function-app-name>

# Restart function app
az functionapp restart -g <resource-group> -n <function-app-name>

# Try deployment again
```

### Issue: Build Artifacts Not Found

**Error:**
```
The system cannot find the path specified: publish\*
```

**Solution:**
```powershell
# Clean and rebuild
dotnet clean
dotnet build -c Release
dotnet publish -c Release -o .\publish
```

### Issue: "Could not load file or assembly"

**Solution:**
- Ensure all dependencies are included in publish output
- Check `TargetFramework` matches runtime version
- Verify all projects reference the same package versions

## Runtime Issues

### Issue: 401 Unauthorized on Protected Endpoints

**Symptoms:**
- Product endpoints return 401 even with valid token

**Solution:**
1. Verify JWT settings match between services:
   ```powershell
   # Check Auth Service settings
   az functionapp config appsettings list -g <rg> -n <auth-app>

   # Check Product Service settings
   az functionapp config appsettings list -g <rg> -n <product-app>
   ```

2. Ensure `JwtSettings__Secret`, `Issuer`, and `Audience` match

3. Test token validity:
   ```powershell
   # Decode JWT at https://jwt.io
   # Verify exp (expiration) is in the future
   # Verify iss and aud match your configuration
   ```

### Issue: "Invalid token" Error

**Solution:**
- Check token hasn't expired
- Verify token is sent as: `Authorization: Bearer <token>`
- Ensure no extra spaces in the header
- Check JWT secret is the same in both services

### Issue: Cosmos DB Throttling (429 Errors)

**Error:**
```
Request rate is large. More Request Units may be needed
```

**Solution:**
- For serverless Cosmos DB, wait and retry (automatic scaling)
- Consider switching to provisioned throughput for predictable load
- Implement exponential backoff in code
- Optimize queries to reduce RU consumption

### Issue: Cold Start Delays

**Symptoms:**
- First request after idle takes 10+ seconds

**Solution:**
- Use Premium or Dedicated plan for always-on instances
- Implement Application Insights availability tests to keep warm
- Consider Azure Front Door for caching

### Issue: Environment Variables Not Loading

**Symptoms:**
- Configuration values are null or default

**Solution:**
```powershell
# Verify app settings
az functionapp config appsettings list -g <resource-group> -n <function-app>

# Update setting
az functionapp config appsettings set -g <resource-group> -n <function-app> --settings "Key=Value"

# Restart function app
az functionapp restart -g <resource-group> -n <function-app>
```

## Testing Issues

### Issue: Test Script Fails with SSL Error

**Error:**
```
The SSL connection could not be established
```

**Solution:**
```powershell
# Skip SSL verification (development only!)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Or use -SkipCertificateCheck in PowerShell 7+
Invoke-RestMethod -Uri $url -SkipCertificateCheck
```

### Issue: CORS Error in Browser

**Error:**
```
Access to fetch at '...' from origin '...' has been blocked by CORS policy
```

**Solution:**
```powershell
# Update CORS settings
az functionapp cors add -g <resource-group> -n <function-app> --allowed-origins "https://yourdomain.com"

# For development, allow all (not recommended for production)
az functionapp cors add -g <resource-group> -n <function-app> --allowed-origins "*"
```

## Monitoring & Debugging

### Enable Detailed Logging

**In local.settings.json:**
```json
{
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AzureWebJobsScriptRoot": "..",
    "AzureFunctionsJobHost__Logging__LogLevel__Default": "Debug"
  }
}
```

**In Azure:**
```powershell
az functionapp config appsettings set -g <rg> -n <function-app> `
  --settings "AzureFunctionsJobHost__Logging__LogLevel__Default=Debug"
```

### View Application Insights Logs

```powershell
# Get recent exceptions
az monitor app-insights query `
  --app <app-insights-name> `
  --analytics-query "exceptions | where timestamp > ago(1h) | order by timestamp desc"

# Get recent traces
az monitor app-insights query `
  --app <app-insights-name> `
  --analytics-query "traces | where timestamp > ago(1h) | order by timestamp desc"
```

### Stream Logs

```powershell
# Stream live logs
az webapp log tail --name <function-app-name> --resource-group <resource-group>

# Or in portal: Function App → Functions → Function Name → Monitor → Logs
```

## Getting Help

If you're still experiencing issues:

1. **Check Azure Status**: https://status.azure.com/
2. **Azure Functions GitHub**: https://github.com/Azure/azure-functions-host/issues
3. **Stack Overflow**: Tag questions with `azure-functions`, `cosmos-db`, `terraform`
4. **Azure Documentation**: https://docs.microsoft.com/azure/

## Common Commands Reference

```powershell
# Check .NET version
dotnet --version

# Check Functions Core Tools version
func --version

# Check Terraform version
terraform version

# Check Azure CLI version
az --version

# List Azure subscriptions
az account list --output table

# Show current subscription
az account show

# List resource groups
az group list --output table

# List function apps in resource group
az functionapp list -g <resource-group> --output table

# Get function app logs
az webapp log download -g <resource-group> -n <function-app>
```
