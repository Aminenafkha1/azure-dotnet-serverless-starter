#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete deployment script that provisions infrastructure and deploys functions.

.DESCRIPTION
    This script orchestrates the complete deployment process.

.PARAMETER Environment
    The environment to deploy to (dev, staging, prod)

.EXAMPLE
    .\deploy-all.ps1 -Environment dev
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Complete Deployment to $Environment" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Step 1: Provision infrastructure
Write-Host "`n[Step 1/2] Provisioning Azure Infrastructure..." -ForegroundColor Magenta
& "$scriptPath\provision-infrastructure.ps1" -Environment $Environment

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure provisioning failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Extract Terraform outputs
Write-Host "`n[Step 2/2] Deploying Function Apps..." -ForegroundColor Magenta

$outputsFile = "$scriptPath\..\infrastructure\terraform-outputs.json"
if (-not (Test-Path $outputsFile)) {
    Write-Host "Terraform outputs file not found!" -ForegroundColor Red
    exit 1
}

$outputs = Get-Content $outputsFile | ConvertFrom-Json

$resourceGroup = $outputs.resource_group_name.value
$authFunctionApp = $outputs.auth_function_app_name.value
$productFunctionApp = $outputs.product_function_app_name.value

Write-Host "Resource Group: $resourceGroup" -ForegroundColor Gray
Write-Host "Auth Function App: $authFunctionApp" -ForegroundColor Gray
Write-Host "Product Function App: $productFunctionApp" -ForegroundColor Gray

# Deploy functions
& "$scriptPath\deploy-functions.ps1" `
    -Environment $Environment `
    -ResourceGroup $resourceGroup `
    -AuthFunctionApp $authFunctionApp `
    -ProductFunctionApp $productFunctionApp

if ($LASTEXITCODE -ne 0) {
    Write-Host "Function deployment failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Deploy Blazor App
Write-Host "`n[Step 3/3] Deploying Blazor WebAssembly App..." -ForegroundColor Magenta
if ($outputs.PSObject.Properties.Name -contains "static_web_app_name") {
    $staticWebAppName = $outputs.static_web_app_name.value

    & "$scriptPath\deploy-blazor.ps1" -ResourceGroupName $resourceGroup -StaticWebAppName $staticWebAppName

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Blazor deployment failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "  Deployment Completed Successfully!" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "`nAuth Service: https://$authFunctionApp.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Product Service: https://$productFunctionApp.azurewebsites.net" -ForegroundColor Cyan

if ($outputs.PSObject.Properties.Name -contains "static_web_app_default_hostname") {
    Write-Host "Blazor App: https://$($outputs.static_web_app_default_hostname.value)" -ForegroundColor Cyan
}
