#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploys Azure Functions to Azure.

.DESCRIPTION
    This script builds and deploys the function apps to Azure.

.PARAMETER Environment
    The environment to deploy to (dev, staging, prod)

.PARAMETER ResourceGroup
    The Azure resource group name

.PARAMETER AuthFunctionApp
    The Auth Function App name

.PARAMETER ProductFunctionApp
    The Product Function App name

.EXAMPLE
    .\deploy-functions.ps1 -Environment dev -ResourceGroup "rg-myapp-dev" -AuthFunctionApp "func-auth-dev" -ProductFunctionApp "func-product-dev"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$AuthFunctionApp,

    [Parameter(Mandatory=$true)]
    [string]$ProductFunctionApp
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Deploying Functions to $Environment" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

# Step 1: Build Auth Service
Write-Host "`n[1/4] Building Auth Service..." -ForegroundColor Yellow
$authPath = Join-Path $rootPath "src\AuthService"
Set-Location $authPath

dotnet publish --configuration Release --output ./publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "Auth Service build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Auth Service built successfully" -ForegroundColor Green

# Step 2: Deploy Auth Service
Write-Host "`n[2/4] Deploying Auth Service to $AuthFunctionApp..." -ForegroundColor Yellow

$authZipPath = Join-Path $authPath "publish.zip"
if (Test-Path $authZipPath) {
    Remove-Item $authZipPath -Force
}

Compress-Archive -Path "$authPath/publish/*" -DestinationPath $authZipPath

az functionapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $AuthFunctionApp `
    --src $authZipPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Auth Service deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Auth Service deployed successfully" -ForegroundColor Green

# Step 3: Build Product Service
Write-Host "`n[3/4] Building Product Service..." -ForegroundColor Yellow
$productPath = Join-Path $rootPath "src\ProductService"
Set-Location $productPath

dotnet publish --configuration Release --output ./publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "Product Service build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Product Service built successfully" -ForegroundColor Green

# Step 4: Deploy Product Service
Write-Host "`n[4/4] Deploying Product Service to $ProductFunctionApp..." -ForegroundColor Yellow

$productZipPath = Join-Path $productPath "publish.zip"
if (Test-Path $productZipPath) {
    Remove-Item $productZipPath -Force
}

Compress-Archive -Path "$productPath/publish/*" -DestinationPath $productZipPath

az functionapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $ProductFunctionApp `
    --src $productZipPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Product Service deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Product Service deployed successfully" -ForegroundColor Green

Set-Location $scriptPath

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "  Deployment Completed Successfully!" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
