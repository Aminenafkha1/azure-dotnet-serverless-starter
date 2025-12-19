# Configure Blazor App to use API Management Gateway

param(
    [Parameter(Mandatory=$false)]
    [string]$ApimGatewayUrl
)

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Configuring Blazor for APIM" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

# Get APIM Gateway URL from Terraform if not provided
if ([string]::IsNullOrEmpty($ApimGatewayUrl)) {
    Write-Host "`nRetrieving API Management Gateway URL from Terraform..." -ForegroundColor Yellow
    Set-Location (Join-Path $rootPath "infrastructure")
    $ApimGatewayUrl = terraform output -raw apim_gateway_url
    Set-Location $rootPath

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($ApimGatewayUrl)) {
        Write-Error "Failed to get APIM Gateway URL from Terraform"
        exit 1
    }
}

Write-Host "APIM Gateway URL: $ApimGatewayUrl" -ForegroundColor Green

# Update appsettings.Production.json
$blazorPath = Join-Path $rootPath "src\BlazorWeb\wwwroot"
$prodSettingsPath = Join-Path $blazorPath "appsettings.Production.json"

$settings = @{
    ApiSettings = @{
        AuthServiceUrl = "$ApimGatewayUrl/auth"
        ProductServiceUrl = "$ApimGatewayUrl/products"
    }
    Logging = @{
        LogLevel = @{
            Default = "Information"
            "Microsoft.AspNetCore" = "Warning"
        }
    }
} | ConvertTo-Json -Depth 10

Set-Content -Path $prodSettingsPath -Value $settings -Force

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  Configuration Updated!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "`nAuth API: $ApimGatewayUrl/auth" -ForegroundColor White
Write-Host "Product API: $ApimGatewayUrl/products" -ForegroundColor White
