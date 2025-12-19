#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sets up Azure Storage for Terraform remote state management.

.DESCRIPTION
    Creates a resource group, storage account, and container for storing Terraform state files.
    Enables state locking and versioning for team collaboration.

.PARAMETER ResourceGroupName
    The name of the resource group for Terraform state

.PARAMETER Location
    The Azure region to create resources

.EXAMPLE
    .\setup-terraform-state.ps1 -ResourceGroupName "rg-terraform-state" -Location "uksouth"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-terraform-state",

    [Parameter(Mandatory=$false)]
    [string]$Location = "uksouth"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Terraform State Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if logged in to Azure
Write-Host "`nChecking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✅ Subscription: $($account.name) ($($account.id))" -ForegroundColor Green

# Create resource group
Write-Host "`nCreating resource group: $ResourceGroupName" -ForegroundColor Yellow
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --tags "Purpose=TerraformState" "ManagedBy=Script"

# Generate random suffix for storage account (must be globally unique)
$randomSuffix = -join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
$storageAccountName = "sttfstate$randomSuffix"

Write-Host "`nCreating storage account: $storageAccountName" -ForegroundColor Yellow
az storage account create `
    --name $storageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --enable-hierarchical-namespace false `
    --tags "Purpose=TerraformState" "ManagedBy=Script"

# Enable versioning
Write-Host "`nEnabling blob versioning..." -ForegroundColor Yellow
az storage account blob-service-properties update `
    --account-name $storageAccountName `
    --enable-versioning true `
    --enable-change-feed true

# Create container for state files
Write-Host "`nCreating container: tfstate" -ForegroundColor Yellow
az storage container create `
    --name tfstate `
    --account-name $storageAccountName `
    --auth-mode login

# Enable soft delete for additional protection
Write-Host "`nEnabling soft delete (7 days retention)..." -ForegroundColor Yellow
az storage blob service-properties delete-policy update `
    --account-name $storageAccountName `
    --days-retained 7 `
    --enable true

# Grant service principal access (if exists)
Write-Host "`nChecking for GitHub Actions service principal..." -ForegroundColor Yellow
$spList = az ad sp list --display-name "sp-github-actions-serverless" --query "[0].appId" -o tsv 2>$null
if ($spList) {
    Write-Host "Found service principal: $spList" -ForegroundColor Green
    Write-Host "Granting Storage Blob Data Contributor role..." -ForegroundColor Yellow
    
    $scope = "/subscriptions/$($account.id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    az role assignment create `
        --assignee $spList `
        --role "Storage Blob Data Contributor" `
        --scope $scope 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Service principal granted access to Terraform state storage" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Role assignment may already exist or permission denied" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  No service principal found (run create-service-principal.ps1 first)" -ForegroundColor Cyan
}

# Get storage account key
$storageKey = az storage account keys list `
    --account-name $storageAccountName `
    --resource-group $ResourceGroupName `
    --query "[0].value" -o tsv

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Write-Host "`nTerraform Backend Configuration:" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Storage Account: $storageAccountName" -ForegroundColor White
Write-Host "Container: tfstate" -ForegroundColor White

Write-Host "`n📋 Add these GitHub Secrets:" -ForegroundColor Yellow
Write-Host "TF_STATE_RESOURCE_GROUP=$ResourceGroupName" -ForegroundColor White
Write-Host "TF_STATE_STORAGE_ACCOUNT=$storageAccountName" -ForegroundColor White

Write-Host "`n📝 To initialize Terraform with remote state:" -ForegroundColor Yellow
Write-Host @"
cd infrastructure
terraform init \
  -backend-config="resource_group_name=$ResourceGroupName" \
  -backend-config="storage_account_name=$storageAccountName" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"
"@ -ForegroundColor White

Write-Host "`n⚠️  Important:" -ForegroundColor Yellow
Write-Host "- Keep the storage account key secure" -ForegroundColor White
Write-Host "- Use Azure AD authentication in CI/CD pipelines" -ForegroundColor White
Write-Host "- Enable diagnostic logs for audit trail" -ForegroundColor White
Write-Host "- Consider geo-redundant storage (GRS) for production" -ForegroundColor White
