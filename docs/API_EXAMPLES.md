# API Examples

This document provides detailed examples of how to interact with the Auth and Product services.

## Authentication Flow

### 1. Register a New User

```bash
curl -X POST https://func-auth-dev-xxxxx.azurewebsites.net/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "userName": "johndoe",
    "password": "SecurePassword123!",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "userName": "johndoe"
  },
  "message": "User registered successfully"
}
```

### 2. Login

```bash
curl -X POST https://func-auth-dev-xxxxx.azurewebsites.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "SecurePassword123!"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "userName": "johndoe",
    "expiresAt": "2025-12-18T13:00:00Z"
  },
  "message": "Login successful"
}
```

## Product Management

### 3. Create a Product (Authenticated)

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST https://func-product-dev-xxxxx.azurewebsites.net/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Laptop Computer",
    "description": "High-performance laptop for developers",
    "price": 1299.99,
    "category": "Electronics",
    "stock": 50
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Laptop Computer",
    "description": "High-performance laptop for developers",
    "price": 1299.99,
    "category": "Electronics",
    "stock": 50,
    "isActive": true,
    "createdBy": "550e8400-e29b-41d4-a716-446655440000",
    "createdAt": "2025-12-18T10:30:00Z",
    "updatedAt": "2025-12-18T10:30:00Z"
  },
  "message": "Product created successfully"
}
```

### 4. Get All Products (Authenticated)

```bash
curl -X GET "https://func-product-dev-xxxxx.azurewebsites.net/api/products?page=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "Laptop Computer",
      "description": "High-performance laptop for developers",
      "price": 1299.99,
      "category": "Electronics",
      "stock": 50,
      "isActive": true,
      "createdBy": "550e8400-e29b-41d4-a716-446655440000",
      "createdAt": "2025-12-18T10:30:00Z",
      "updatedAt": "2025-12-18T10:30:00Z"
    }
  ]
}
```

### 5. Get Product by ID (Authenticated)

```bash
curl -X GET https://func-product-dev-xxxxx.azurewebsites.net/api/products/123e4567-e89b-12d3-a456-426614174000 \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Laptop Computer",
    "description": "High-performance laptop for developers",
    "price": 1299.99,
    "category": "Electronics",
    "stock": 50,
    "isActive": true,
    "createdBy": "550e8400-e29b-41d4-a716-446655440000",
    "createdAt": "2025-12-18T10:30:00Z",
    "updatedAt": "2025-12-18T10:30:00Z"
  }
}
```

## PowerShell Examples

### Complete Workflow

```powershell
# Base URLs
$authUrl = "https://func-auth-dev-xxxxx.azurewebsites.net"
$productUrl = "https://func-product-dev-xxxxx.azurewebsites.net"

# 1. Register
$registerBody = @{
    email = "jane.smith@example.com"
    userName = "janesmith"
    password = "SecurePass123!"
    firstName = "Jane"
    lastName = "Smith"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "$authUrl/api/auth/register" `
    -Method Post -Body $registerBody -ContentType "application/json"

Write-Host "Registered: $($registerResponse.data.email)"

# 2. Login
$loginBody = @{
    email = "jane.smith@example.com"
    password = "SecurePass123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$authUrl/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.data.token
Write-Host "Token: $token"

# 3. Create Product
$headers = @{ Authorization = "Bearer $token" }

$productBody = @{
    name = "Wireless Mouse"
    description = "Ergonomic wireless mouse"
    price = 29.99
    category = "Accessories"
    stock = 200
} | ConvertTo-Json

$productResponse = Invoke-RestMethod -Uri "$productUrl/api/products" `
    -Method Post -Headers $headers -Body $productBody -ContentType "application/json"

Write-Host "Product Created: $($productResponse.data.name)"

# 4. Get All Products
$productsResponse = Invoke-RestMethod -Uri "$productUrl/api/products?page=1&pageSize=10" `
    -Method Get -Headers $headers

Write-Host "Total Products: $($productsResponse.data.Count)"
```

## Error Responses

### Validation Error
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "The Email field is not a valid e-mail address.",
    "The Password field must be at least 6 characters long."
  ]
}
```

### Authentication Error
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

### Unauthorized Access
```json
{
  "success": false,
  "message": "Missing authorization header"
}
```

### Not Found
```json
{
  "success": false,
  "message": "Product not found"
}
```

## Postman Collection

You can import these examples into Postman:

1. Create a new collection
2. Add environment variables:
   - `auth_base_url`: Your Auth Service URL
   - `product_base_url`: Your Product Service URL
   - `token`: Will be set automatically after login

3. Add the following requests with the above examples
4. Use a test script in the login request to save the token:
   ```javascript
   pm.test("Save token", function () {
       var jsonData = pm.response.json();
       pm.environment.set("token", jsonData.data.token);
   });
   ```
