# Deploy Blazor WebAssembly App to Azure Static Web Apps
# This script builds the Blazor app and deploys it to Azure Static Web Apps

param(
    [string]$ResourceGroupName,
    [string]$StaticWebAppName
)

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Deploying Blazor App to Azure" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$blazorPath = Join-Path $rootPath "src\BlazorWeb"

# Get deployment token
Write-Host "`nGetting Static Web App deployment token..." -ForegroundColor Yellow
if ($ResourceGroupName -and $StaticWebAppName) {
    $deploymentToken = az staticwebapp secrets list `
        --name $StaticWebAppName `
        --resource-group $ResourceGroupName `
        --query "properties.apiKey" `
        --output tsv
} else {
    # Get from Terraform outputs
    Set-Location (Join-Path $rootPath "infrastructure")
    $deploymentToken = terraform output -raw static_web_app_api_key
    Set-Location $rootPath
}

if (-not $deploymentToken) {
    Write-Error "Failed to get deployment token"
    exit 1
}

# Build the Blazor app
Write-Host "`nBuilding Blazor WebAssembly app..." -ForegroundColor Yellow
Set-Location $blazorPath
dotnet build --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

Write-Host "`nPublishing Blazor app..." -ForegroundColor Yellow
dotnet publish --configuration Release --output publish
if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed"
    exit 1
}

# Install SWA CLI if not already installed
Write-Host "`nChecking for SWA CLI..." -ForegroundColor Yellow
$swaCli = Get-Command swa -ErrorAction SilentlyContinue
if (-not $swaCli) {
    Write-Host "Installing Azure Static Web Apps CLI..." -ForegroundColor Yellow
    npm install -g @azure/static-web-apps-cli
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install SWA CLI"
        exit 1
    }
}

# Deploy to Azure Static Web Apps
Write-Host "`nDeploying to Azure Static Web Apps..." -ForegroundColor Yellow
Set-Location $blazorPath
swa deploy ./publish/wwwroot `
    --deployment-token $deploymentToken `
    --env production

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed"
    exit 1
}

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  Blazor App Deployed Successfully!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Set-Location $rootPath
