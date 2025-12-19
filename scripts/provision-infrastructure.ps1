#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Provisions Azure infrastructure using Terraform.

.DESCRIPTION
    This script initializes Terraform and applies the infrastructure configuration.

.PARAMETER Environment
    The environment to deploy (dev, staging, prod)

.PARAMETER AutoApprove
    Automatically approve the Terraform plan

.EXAMPLE
    .\provision-infrastructure.ps1 -Environment dev
    .\provision-infrastructure.ps1 -Environment prod -AutoApprove
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "Provisioning infrastructure for environment: $Environment" -ForegroundColor Cyan

# Navigate to infrastructure directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$scriptPath\..\infrastructure"

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "Creating terraform.tfvars from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "Please edit terraform.tfvars with your configuration and run this script again." -ForegroundColor Red
    exit 1
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

# Validate configuration
Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
terraform validate

# Plan
Write-Host "`nCreating Terraform plan..." -ForegroundColor Yellow
terraform plan -var="environment=$Environment" -out=tfplan

# Apply
if ($AutoApprove) {
    Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
    terraform apply -auto-approve tfplan
} else {
    Write-Host "`nReview the plan above. Do you want to apply these changes? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq 'y' -or $response -eq 'Y') {
        terraform apply tfplan
    } else {
        Write-Host "Deployment cancelled." -ForegroundColor Red
        exit 0
    }
}

# Show outputs
Write-Host "`nInfrastructure outputs:" -ForegroundColor Cyan
terraform output

# Save outputs to file
Write-Host "`nSaving outputs to terraform-outputs.json..." -ForegroundColor Yellow
terraform output -json | Out-File -FilePath "terraform-outputs.json"

Write-Host "`nInfrastructure provisioning completed successfully!" -ForegroundColor Green

Set-Location $scriptPath
