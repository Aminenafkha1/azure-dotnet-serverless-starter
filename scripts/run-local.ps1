# Run all services locally (Auth, Product, Blazor)

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Starting All Services Locally" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

# Build projects if not skipped
if (-not $SkipBuild) {
    Write-Host "`nBuilding solution..." -ForegroundColor Yellow
    Set-Location $rootPath
    dotnet build ServerlessStarter.sln --configuration Debug
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
}

# Start Auth Service
Write-Host "`nStarting Auth Service on port 7071..." -ForegroundColor Green
$authPath = Join-Path $rootPath "src\AuthService"
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$authPath'; func start --port 7071"

# Wait a bit
Start-Sleep -Seconds 2

# Start Product Service
Write-Host "Starting Product Service on port 7072..." -ForegroundColor Green
$productPath = Join-Path $rootPath "src\ProductService"
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$productPath'; func start --port 7072"

# Wait a bit
Start-Sleep -Seconds 2

# Start Blazor App
Write-Host "Starting Blazor App on port 5000..." -ForegroundColor Green
$blazorPath = Join-Path $rootPath "src\BlazorWeb"
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$blazorPath'; dotnet watch run"

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  All Services Started!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "`nAuth Service:    http://localhost:7071" -ForegroundColor White
Write-Host "Product Service: http://localhost:7072" -ForegroundColor White
Write-Host "Blazor App:      http://localhost:5000" -ForegroundColor Cyan
Write-Host "`nPress Ctrl+C in each window to stop the services." -ForegroundColor Gray
