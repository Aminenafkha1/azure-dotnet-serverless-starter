#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates an Azure Service Principal for GitHub Actions CI/CD.

.DESCRIPTION
    Creates a service principal with Contributor role and outputs credentials
    for GitHub Secrets configuration.

.PARAMETER ServicePrincipalName
    The name of the service principal

.PARAMETER Subscription
    The Azure subscription ID (optional, uses current subscription if not provided)

.EXAMPLE
    .\create-service-principal.ps1 -ServicePrincipalName "sp-github-actions-serverless"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServicePrincipalName = "sp-github-actions-serverless",

    [Parameter(Mandatory=$false)]
    [string]$Subscription = ""
)

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Service Principal Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Get current subscription
if ([string]::IsNullOrEmpty($Subscription)) {
    $account = az account show | ConvertFrom-Json
    $Subscription = $account.id
    Write-Host "`nUsing subscription: $($account.name)" -ForegroundColor Green
} else {
    az account set --subscription $Subscription
    Write-Host "`nSubscription set to: $Subscription" -ForegroundColor Green
}

# Create service principal
Write-Host "`nCreating service principal: $ServicePrincipalName" -ForegroundColor Yellow
$sp = az ad sp create-for-rbac `
    --name $ServicePrincipalName `
    --role Contributor `
    --scopes "/subscriptions/$Subscription" | ConvertFrom-Json

if (-not $sp) {
    Write-Error "Failed to create service principal"
    exit 1
}

# Grant User Access Administrator role for managing role assignments
Write-Host "Granting User Access Administrator role..." -ForegroundColor Yellow
az role assignment create `
    --assignee $sp.appId `
    --role "User Access Administrator" `
    --scope "/subscriptions/$Subscription" | Out-Null

Write-Host "✅ Service principal created with required roles" -ForegroundColor Green

# Get tenant ID
$account = az account show | ConvertFrom-Json
$tenantId = $account.tenantId

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  Service Principal Created!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Write-Host "`n📋 GitHub Secrets Configuration:" -ForegroundColor Yellow
Write-Host "`nAdd these secrets to your GitHub repository:" -ForegroundColor Cyan
Write-Host "(Settings → Secrets and variables → Actions → New repository secret)" -ForegroundColor Gray

Write-Host "`nAZURE_CREDENTIALS (entire JSON block):" -ForegroundColor Yellow
$azureCredentials = @{
    clientId = $sp.clientId
    clientSecret = $sp.clientSecret
    subscriptionId = $sp.subscriptionId
    tenantId = $sp.tenantId
} | ConvertTo-Json -Compress
Write-Host $azureCredentials -ForegroundColor White

Write-Host "`nIndividual secrets:" -ForegroundColor Yellow
Write-Host "AZURE_CLIENT_ID=$($sp.clientId)" -ForegroundColor White
Write-Host "AZURE_CLIENT_SECRET=$($sp.clientSecret)" -ForegroundColor White
Write-Host "AZURE_SUBSCRIPTION_ID=$($sp.subscriptionId)" -ForegroundColor White
Write-Host "AZURE_TENANT_ID=$($sp.tenantId)" -ForegroundColor White

# Get current user object ID for resource suffix
$currentUser = az ad signed-in-user show | ConvertFrom-Json
$objectIdShort = $currentUser.id.Substring(0, 8)

Write-Host "`nRESOURCE_SUFFIX=$objectIdShort" -ForegroundColor White

Write-Host "`n⚠️  Security Notes:" -ForegroundColor Yellow
Write-Host "- Store these credentials securely" -ForegroundColor White
Write-Host "- Never commit credentials to source control" -ForegroundColor White
Write-Host "- Rotate credentials regularly (every 90 days recommended)" -ForegroundColor White
Write-Host "- Use least privilege principle (consider custom roles)" -ForegroundColor White
Write-Host "- Enable Azure AD Conditional Access for service principals" -ForegroundColor White

Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Add all secrets to GitHub repository" -ForegroundColor White
Write-Host "2. Run: .\setup-terraform-state.ps1" -ForegroundColor White
Write-Host "3. Add TF_STATE_RESOURCE_GROUP and TF_STATE_STORAGE_ACCOUNT to GitHub secrets" -ForegroundColor White
Write-Host "4. Push code to trigger GitHub Actions workflow" -ForegroundColor White

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
