# DevOps & CI/CD Guide

This document describes the complete DevOps setup for the Serverless Starter project, including CI/CD pipelines, infrastructure management, and deployment strategies.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Repository                      │
├─────────────────────────────────────────────────────────────┤
│  Pull Request  →  Terraform Plan + Security Scan            │
│  Push to main  →  Terraform Apply + Deploy Functions        │
│  Manual Deploy →  Workflow Dispatch (any environment)       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflows                 │
├─────────────────────────────────────────────────────────────┤
│  terraform-plan.yml       → Plan infrastructure changes     │
│  terraform-apply.yml      → Provision Azure resources       │
│  deploy-functions.yml     → Deploy Azure Functions          │
│  deploy-blazor.yml        → Deploy Blazor WebAssembly       │
│  security-scan.yml        → Security & vulnerability scan   │
│  cost-estimation.yml      → Infrastructure cost estimation  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Azure Infrastructure                     │
├─────────────────────────────────────────────────────────────┤
│  Terraform State Storage  → Azure Blob Storage (versioned)  │
│  Function Apps           → Auth + Product Services          │
│  API Management          → Unified API Gateway              │
│  Key Vault              → Secret Management                 │
│  Cosmos DB              → Database                          │
│  Storage Account        → Blazor Static Website             │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Repository Structure

```
.github/workflows/
├── terraform-plan.yml          # Infrastructure planning
├── terraform-apply.yml         # Infrastructure provisioning
├── deploy-functions.yml        # Function deployment
├── deploy-blazor.yml           # Blazor deployment
├── security-scan.yml           # Security scanning
└── cost-estimation.yml         # Cost estimation

infrastructure/
├── backend.tf                  # Remote state configuration
├── main.tf                     # Provider configuration
├── resources.tf                # Azure resources
├── key-vault.tf               # Key Vault setup
├── api-management.tf          # APIM configuration
├── dev.tfvars                 # Dev environment variables
├── staging.tfvars             # Staging environment variables
└── prod.tfvars                # Production environment variables

scripts/
├── setup-terraform-state.ps1   # Initialize remote state
├── create-service-principal.ps1 # Create CI/CD credentials
└── configure-apim.ps1          # Configure APIM endpoints
```

## 🚀 Initial Setup

### 1. Create Azure Service Principal

The service principal provides credentials for GitHub Actions to deploy to Azure.

```powershell
# Run this script to create service principal
.\scripts\create-service-principal.ps1

# Output will provide GitHub Secrets to configure
```

### 2. Setup Terraform Remote State

Terraform state must be stored in Azure Storage for team collaboration and CI/CD.

```powershell
# Create storage account for Terraform state
.\scripts\setup-terraform-state.ps1

# This creates:
# - Resource group: rg-terraform-state
# - Storage account: sttfstate<random>
# - Container: tfstate
# - Blob versioning enabled
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

#### Required Secrets:

```yaml
# Azure Authentication
AZURE_CREDENTIALS:         # JSON from create-service-principal.ps1
AZURE_CLIENT_ID:          # Service principal client ID
AZURE_CLIENT_SECRET:      # Service principal secret
AZURE_SUBSCRIPTION_ID:    # Your Azure subscription ID
AZURE_TENANT_ID:          # Your Azure AD tenant ID

# Terraform State
TF_STATE_RESOURCE_GROUP:  # e.g., rg-terraform-state
TF_STATE_STORAGE_ACCOUNT: # e.g., sttfstatexxxxxxxx

# Deployment
RESOURCE_SUFFIX:          # e.g., njyenins (your unique suffix)

# Optional - for cost estimation
INFRACOST_API_KEY:        # From https://www.infracost.io/
SNYK_TOKEN:              # From https://snyk.io/
```

#### Function App Publish Profiles:

Get publish profiles from Azure Portal or CLI:

```powershell
# Get Auth Function publish profile
az functionapp deployment list-publishing-profiles \
  --name func-auth-dev-njyenins \
  --resource-group rg-serverless-starter-dev-njyenins \
  --xml

# Add to GitHub as: AZURE_FUNCTIONAPP_PUBLISH_PROFILE_AUTH

# Get Product Function publish profile
az functionapp deployment list-publishing-profiles \
  --name func-product-dev-njyenins \
  --resource-group rg-serverless-starter-dev-njyenins \
  --xml

# Add to GitHub as: AZURE_FUNCTIONAPP_PUBLISH_PROFILE_PRODUCT
```

## 🔄 CI/CD Workflows

### Workflow: Terraform Plan (Pull Request)

**Trigger**: Pull request to `main` or `develop` with infrastructure changes

**Purpose**: Preview infrastructure changes before applying

**Steps**:
1. Checkout code
2. Setup Terraform
3. Run `terraform fmt -check`
4. Initialize with remote state backend
5. Run `terraform validate`
6. Run `terraform plan` for each environment (dev, staging, prod)
7. Post plan output as PR comment
8. Upload plan artifacts

**Example Output**:
```
#### Terraform Format and Style 🖌 success
#### Terraform Initialization ⚙️ success
#### Terraform Validation 🤖 success
#### Terraform Plan 📖 success

Plan: 3 to add, 1 to change, 0 to destroy
```

### Workflow: Terraform Apply (Push to main)

**Trigger**: Push to `main` branch with infrastructure changes, or manual dispatch

**Purpose**: Provision/update Azure infrastructure

**Steps**:
1. Checkout code
2. Setup Terraform
3. Azure login
4. Initialize with remote state
5. Run `terraform plan`
6. Run `terraform apply -auto-approve`
7. Save outputs (APIM URL, Key Vault name, etc.)
8. Upload outputs as artifacts

**Deployment Approval**:
- Configure environment protection rules in GitHub
- Require manual approval for production

### Workflow: Deploy Functions

**Trigger**: Push to `main` with src changes (excluding Blazor), or manual dispatch

**Purpose**: Build and deploy Azure Functions

**Steps**:
1. **Build Stage**:
   - Setup .NET 8.0
   - Restore dependencies
   - Build solution (Release configuration)
   - Run unit tests
   - Publish Auth Service
   - Publish Product Service
   - Upload artifacts

2. **Deploy Auth Service**:
   - Download artifact
   - Azure login
   - Deploy to Function App
   - Restart Function App

3. **Deploy Product Service**:
   - Download artifact
   - Azure login
   - Deploy to Function App
   - Restart Function App

4. **Smoke Tests**:
   - Get APIM gateway URL
   - Test Auth Service health endpoint
   - Test Product Service health endpoint
   - Test user registration

### Workflow: Deploy Blazor

**Trigger**: Push to `main` with Blazor changes, or manual dispatch

**Purpose**: Build and deploy Blazor WebAssembly app

**Steps**:
1. Setup .NET 9.0
2. Get APIM gateway URL from Azure
3. Update `appsettings.Production.json` with APIM endpoints
4. Build Blazor app (Release configuration)
5. Create/update Azure Storage Static Website
6. Upload build artifacts to `$web` container
7. Purge CDN cache (if CDN configured)

### Workflow: Security Scan

**Trigger**: Push to `main`/`develop`, pull requests, or weekly schedule

**Purpose**: Continuous security monitoring

**Scans**:
1. **Code Security**: Trivy filesystem scan
2. **Dependencies**: Dependency-Check for known vulnerabilities
3. **Terraform**: tfsec and Checkov for infrastructure misconfigurations
4. **Secrets**: Gitleaks for leaked credentials
5. **.NET Security**: `dotnet list package --vulnerable`
6. **SAST**: Snyk code analysis

**Reports**: Uploaded to GitHub Security tab (SARIF format)

### Workflow: Cost Estimation

**Trigger**: Pull request with infrastructure changes

**Purpose**: Preview infrastructure costs before applying

**Steps**:
1. Setup Infracost
2. Run `infracost breakdown` on Terraform code
3. Post cost estimate as PR comment
4. Fail if monthly cost exceeds threshold ($500 default)

**Example Output**:
```
Monthly Cost Estimate:
- Cosmos DB (Serverless):     $0.25
- Function Apps (Consumption): $0.00
- API Management (Consumption): $0.00
- Key Vault:                   $0.50
- Storage:                     $0.10
────────────────────────────────────
Total:                         $0.85
```

## 🌍 Multi-Environment Strategy

### Environment Configuration

```
┌─────────────┬─────────────┬──────────────┬──────────────┐
│ Environment │ Branch      │ Approval     │ Auto Deploy  │
├─────────────┼─────────────┼──────────────┼──────────────┤
│ Dev         │ develop     │ None         │ Yes          │
│ Staging     │ main        │ Optional     │ Yes          │
│ Production  │ main        │ Required     │ Manual       │
└─────────────┴─────────────┴──────────────┴──────────────┘
```

### Terraform State Files

Each environment has its own state file:

```
Azure Storage: sttfstate<random>/tfstate/
├── dev.terraform.tfstate
├── staging.terraform.tfstate
└── prod.terraform.tfstate
```

### Variable Files

Environment-specific configurations:

```terraform
# dev.tfvars
environment = "dev"
location    = "uksouth"

# staging.tfvars
environment = "staging"
location    = "uksouth"

# prod.tfvars
environment = "prod"
location    = "uksouth"
```

## 📊 Monitoring & Observability

### Application Insights

All services integrated with Application Insights:

```
Dashboard URL:
https://portal.azure.com/#@/resource/subscriptions/{sub}/resourceGroups/{rg}/providers/microsoft.insights/components/appi-serverless-starter-{env}-{suffix}
```

**Metrics**:
- Request rate
- Response time
- Failure rate
- Dependency calls
- Custom events

### APIM Analytics

API Management provides built-in analytics:

```
APIM URL:
https://portal.azure.com/#@/resource/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ApiManagement/service/apim-serverless-starter-{env}-{suffix}
```

**Metrics**:
- API calls per endpoint
- Latency percentiles
- Error rates
- Rate limit hits
- Cache hit ratio

### GitHub Actions Insights

Monitor workflow runs:

```
Repository → Actions → Workflows
- Success/failure rates
- Duration trends
- Deployment frequency
```

## 🔐 Security Best Practices

### Secrets Management

✅ **DO**:
- Use GitHub Secrets for all credentials
- Rotate service principal credentials every 90 days
- Use Azure Key Vault for application secrets
- Enable Azure AD authentication where possible

❌ **DON'T**:
- Commit secrets to source control
- Use long-lived passwords
- Share credentials between environments
- Store secrets in pipeline logs

### RBAC Configuration

```yaml
Service Principal Roles:
├── Contributor (Subscription level) - For Terraform
├── Key Vault Administrator - For secret management
└── Storage Blob Data Contributor - For Terraform state

GitHub Environments:
├── dev: No approval required
├── staging: Optional approval
└── prod: Required approvers (2+)
```

### Network Security

Consider implementing:
- Private endpoints for Function Apps
- VNet integration
- Azure Firewall
- IP restrictions on APIM
- Web Application Firewall (WAF)

## 🎯 Deployment Strategies

### Blue-Green Deployment

Deploy to staging slot first, then swap:

```powershell
# Deploy to staging slot
az functionapp deployment source config-zip \
  --name func-auth-prod-njyenins \
  --resource-group rg-serverless-starter-prod-njyenins \
  --slot staging \
  --src function-app.zip

# Verify staging
curl https://func-auth-prod-njyenins-staging.azurewebsites.net/health

# Swap slots
az functionapp deployment slot swap \
  --name func-auth-prod-njyenins \
  --resource-group rg-serverless-starter-prod-njyenins \
  --slot staging
```

### Canary Deployment

Route small percentage of traffic to new version:

```xml
<!-- APIM Policy -->
<choose>
  <when condition="@(new Random().Next(100) < 10)">
    <!-- 10% traffic to new version -->
    <set-backend-service base-url="https://func-auth-v2.azurewebsites.net" />
  </when>
  <otherwise>
    <!-- 90% traffic to current version -->
    <set-backend-service base-url="https://func-auth-v1.azurewebsites.net" />
  </otherwise>
</choose>
```

### Rollback Strategy

Rollback to previous version:

```powershell
# List deployments
az functionapp deployment list \
  --name func-auth-prod-njyenins \
  --resource-group rg-serverless-starter-prod-njyenins

# Rollback to specific deployment
az functionapp deployment source delete \
  --name func-auth-prod-njyenins \
  --resource-group rg-serverless-starter-prod-njyenins \
  --deployment-id <id>
```

## 📈 Cost Optimization

### Resource Tagging

All resources tagged for cost tracking:

```terraform
tags = {
  Environment = "dev"
  Project     = "ServerlessStarter"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
```

### Cost Alerts

Setup budget alerts:

```powershell
az consumption budget create \
  --budget-name serverless-starter-monthly \
  --amount 100 \
  --time-grain Monthly \
  --threshold 80 \
  --notification-key notification1 \
  --notification-email your-email@example.com
```

### Auto-Shutdown (Dev Environment)

Schedule shutdown of non-production resources:

```yaml
# Add to GitHub Actions schedule
- cron: '0 20 * * 1-5' # 8 PM weekdays
  run: |
    az functionapp stop --name func-auth-dev-njyenins
    az functionapp stop --name func-product-dev-njyenins
```

## 🧪 Testing Strategy

### Unit Tests

Run before deployment:

```powershell
dotnet test ServerlessStarter.sln --configuration Release
```

### Integration Tests

Test deployed services:

```bash
# Health checks
curl https://apim-url.azure-api.net/auth/api/auth/health
curl https://apim-url.azure-api.net/products/api/products/health

# End-to-end flow
curl -X POST https://apim-url.azure-api.net/auth/api/auth/register \
  -d '{"email":"test@example.com","password":"Test@123"}'
```

### Load Testing

Use Azure Load Testing:

```yaml
# load-test.yml
testPlan: jmeter-test-plan.jmx
engineInstances: 5
duration: 300 # 5 minutes
threads: 100
rampUpTime: 60
```

## 📝 Troubleshooting

### Pipeline Failures

**Terraform Init Failed**:
```powershell
# Verify backend configuration
az storage account show --name sttfstatexxxxxxxx

# Check permissions
az role assignment list --assignee <service-principal-id>
```

**Function Deployment Failed**:
```powershell
# Check function app logs
az functionapp log tail --name func-auth-dev-njyenins

# Verify app settings
az functionapp config appsettings list \
  --name func-auth-dev-njyenins
```

**State Locking Issue**:
```powershell
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## 🚀 Next Steps

1. **Setup GitHub Environments**:
   - Settings → Environments → New environment
   - Configure protection rules
   - Add environment secrets

2. **Enable Branch Protection**:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

3. **Configure Notifications**:
   - Slack/Teams integration for deployment notifications
   - Email alerts for failed deployments

4. **Implement Advanced Monitoring**:
   - Custom Application Insights dashboards
   - Azure Monitor alerts
   - PagerDuty/Opsgenie integration

5. **Add More Environments**:
   - QA environment for testing
   - Performance testing environment
   - Disaster recovery environment

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Functions Deployment](https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies)
- [Azure DevOps Best Practices](https://docs.microsoft.com/en-us/azure/architecture/checklist/dev-ops)
