#!/usr/bin/env pwsh

param(
    [string]$BaseUrlAuth = "http://localhost:7071",
    [string]$BaseUrlProduct = "http://localhost:7072"
)

$ErrorActionPreference = "Stop"

Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "  API Testing Suite" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "Auth Service: $BaseUrlAuth" -ForegroundColor Gray
Write-Host "Product Service: $BaseUrlProduct" -ForegroundColor Gray

# Generate random user
$randomId = Get-Random -Minimum 1000 -Maximum 9999
$testUser = @{
    email = "testuser$randomId@example.com"
    userName = "testuser$randomId"
    password = "TestPassword123!"
    firstName = "Test"
    lastName = "User"
}

# Test 1: Register User
Write-Host "`n[Test 1] User Registration..." -ForegroundColor Yellow
try {
    $registerResponse = Invoke-RestMethod -Uri "$BaseUrlAuth/api/auth/register" `
        -Method Post `
        -Body ($testUser | ConvertTo-Json) `
        -ContentType "application/json"

    if ($registerResponse.success) {
        Write-Host "[PASS] User registered: $($registerResponse.data.email)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Registration failed: $($registerResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[FAIL] Registration error: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Login
Write-Host "`n[Test 2] User Login..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email = $testUser.email
        password = $testUser.password
    }

    $loginResponse = Invoke-RestMethod -Uri "$BaseUrlAuth/api/auth/login" `
        -Method Post `
        -Body ($loginBody | ConvertTo-Json) `
        -ContentType "application/json"

    if ($loginResponse.success) {
        $token = $loginResponse.data.token
        Write-Host "[PASS] Login successful. Token received." -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Login failed: $($loginResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[FAIL] Login error: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Create Product (Authenticated)
Write-Host "`n[Test 3] Create Product (Authenticated)..." -ForegroundColor Yellow
try {
    $productData = @{
        name = "Test Product $randomId"
        description = "This is a test product"
        price = 99.99
        category = "Electronics"
        stock = 100
    }

    $headers = @{
        Authorization = "Bearer $token"
    }

    $createResponse = Invoke-RestMethod -Uri "$BaseUrlProduct/api/products" `
        -Method Post `
        -Headers $headers `
        -Body ($productData | ConvertTo-Json) `
        -ContentType "application/json"

    if ($createResponse.success) {
        $productId = $createResponse.data.id
        Write-Host "[PASS] Product created: $($createResponse.data.name)" -ForegroundColor Green
        Write-Host "       Product ID: $productId" -ForegroundColor Gray
    } else {
        Write-Host "[FAIL] Product creation failed: $($createResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Product creation error: $_" -ForegroundColor Red
}

# Test 4: Get Products (Authenticated)
Write-Host "`n[Test 4] Get Products (Authenticated)..." -ForegroundColor Yellow
try {
    $getResponse = Invoke-RestMethod -Uri "$BaseUrlProduct/api/products" `
        -Method Get `
        -Headers $headers

    if ($getResponse.success) {
        $productCount = $getResponse.data.Count
        Write-Host "[PASS] Retrieved $productCount product(s)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Get products failed: $($getResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Get products error: $_" -ForegroundColor Red
}

# Test 5: Get Product by ID (Authenticated)
if ($productId) {
    Write-Host "`n[Test 5] Get Product by ID (Authenticated)..." -ForegroundColor Yellow
    try {
        $getOneResponse = Invoke-RestMethod -Uri "$BaseUrlProduct/api/products/$productId" `
            -Method Get `
            -Headers $headers

        if ($getOneResponse.success) {
            Write-Host "[PASS] Retrieved product: $($getOneResponse.data.name)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Get product failed: $($getOneResponse.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "[FAIL] Get product error: $_" -ForegroundColor Red
    }
}

# Test 6: Unauthorized Access Test
Write-Host "`n[Test 6] Unauthorized Access Test..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "$BaseUrlProduct/api/products" -Method Get -ErrorAction Stop
    Write-Host "[FAIL] Unauthorized access was allowed (security issue!)" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 401) {
        Write-Host "[PASS] Unauthorized access correctly blocked" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Unexpected error: $_" -ForegroundColor Red
    }
}

Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "  Testing Complete!" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
