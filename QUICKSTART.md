# Quick Start Guide

Get up and running with Azure Serverless Starter in minutes!

## ⚡ Prerequisites

Install these tools before starting:

1. **.NET 9 SDK**: https://dotnet.microsoft.com/download/dotnet/9.0
2. **Azure Functions Core Tools**: `npm install -g azure-functions-core-tools@4`
3. **Azure CLI**: https://docs.microsoft.com/cli/azure/install-azure-cli
4. **Terraform**: https://www.terraform.io/downloads

## 🚀 Local Development (5 minutes)

### Step 1: Clone and Build

```powershell
# Clone repository
git clone <your-repo-url>
cd serveless

# Build solution
dotnet build
```

### Step 2: Start Services

```powershell
# Option A: Use the script
.\scripts\run-local.ps1

# Option B: Manual start (two terminals)
# Terminal 1
cd src\AuthService
func start --port 7071

# Terminal 2
cd src\ProductService
func start --port 7072
```

### Step 3: Test

```powershell
# Run test suite
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

**That's it! Your services are running! 🎉**

## ☁️ Azure Deployment (10 minutes)

### Step 1: Login to Azure

```powershell
az login
az account set --subscription "Your-Subscription-Name"
```

### Step 2: Configure Terraform

```powershell
cd infrastructure
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars - minimal required changes:
# - project_name: "yourproject"
# - environment: "dev"
# - location: "eastus"
```

### Step 3: Deploy Everything

```powershell
cd ..\scripts
.\deploy-all.ps1 -Environment dev
```

This single command will:
- ✅ Create all Azure resources
- ✅ Deploy both Function Apps
- ✅ Configure environment variables
- ✅ Output service URLs

### Step 4: Test Deployed Services

```powershell
# Get URLs from Terraform output
cd ..\infrastructure
$outputs = terraform output -json | ConvertFrom-Json
$authUrl = "https://$($outputs.auth_function_app_default_hostname.value)"
$productUrl = "https://$($outputs.product_function_app_default_hostname.value)"

# Test
cd ..\scripts
.\test-apis.ps1 -BaseUrlAuth $authUrl -BaseUrlProduct $productUrl
```

## 📝 Try the APIs

### 1. Register a User

```powershell
$registerBody = @{
    email = "test@example.com"
    userName = "testuser"
    password = "TestPass123!"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:7071/api/auth/register" `
    -Method Post -Body $registerBody -ContentType "application/json"
```

### 2. Login

```powershell
$loginBody = @{
    email = "test@example.com"
    password = "TestPass123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:7071/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.data.token
```

### 3. Create a Product

```powershell
$productBody = @{
    name = "Test Product"
    price = 99.99
    stock = 50
} | ConvertTo-Json

$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Uri "http://localhost:7072/api/products" `
    -Method Post -Headers $headers -Body $productBody -ContentType "application/json"
```

### 4. Get Products

```powershell
Invoke-RestMethod -Uri "http://localhost:7072/api/products" `
    -Method Get -Headers $headers
```

## 🎯 What You Get

After following this guide, you have:

- ✅ **Two microservices** running locally or in Azure
- ✅ **Authentication system** with JWT tokens
- ✅ **Product management** with CRUD operations
- ✅ **Cosmos DB** for data persistence
- ✅ **Application Insights** for monitoring
- ✅ **Production-ready infrastructure** via Terraform

## 📚 Next Steps

### Customize Your Project

1. **Add More Endpoints**
   - Create new functions in `src/AuthService/Functions/` or `src/ProductService/Functions/`
   - Follow existing patterns

2. **Add More Models**
   - Add models in respective `Models/` folders
   - Create Cosmos DB containers in `infrastructure/resources.tf`

3. **Configure Security**
   - Update JWT settings in `infrastructure/variables.tf`
   - Configure CORS policies
   - Add API Management

### Learn More

- **Full Documentation**: See [README.md](../README.md)
- **API Examples**: See [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)
- **Troubleshooting**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 🆘 Common Issues

### Port Already in Use
```powershell
# Use different ports
func start --port 7073
```

### Terraform Errors
```powershell
# Re-initialize Terraform
cd infrastructure
terraform init -upgrade
```

### Build Errors
```powershell
# Clean and rebuild
dotnet clean
dotnet build
```

## 💡 Tips

1. **Use Cosmos DB Emulator** for local development (faster, free)
2. **Enable Application Insights** in dev for debugging
3. **Use variables** in Terraform for different environments
4. **Version control** your `terraform.tfvars` (but exclude secrets!)

## 🎓 Understanding the Architecture

```
┌─────────────────┐
│   Client App    │
└────────┬────────┘
         │
    ┌────┴─────┐
    │          │
┌───▼────┐ ┌──▼──────┐
│  Auth  │ │ Product │
│Service │ │ Service │
└───┬────┘ └──┬──────┘
    │         │
    └────┬────┘
         │
    ┌────▼─────┐
    │ Cosmos DB│
    └──────────┘
```

- **Auth Service**: Handles registration, login, JWT generation
- **Product Service**: Manages products, secured with JWT
- **Cosmos DB**: Stores users and products in separate containers

## 🤝 Get Help

- **Issues**: Open an issue on GitHub
- **Documentation**: Check `/docs` folder
- **Examples**: See API_EXAMPLES.md

---

**Happy Coding! 🚀**
