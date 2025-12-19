# Azure Serverless Starter - Production Ready

A production-ready serverless starter project on Azure using **Azure Functions (isolated worker)**, **.NET 9**, **Azure Cosmos DB**, **Terraform**, **Azure API Management**, and **Azure Key Vault**. This solution includes complete authentication and product management microservices with JWT-based security, centralized secret management, and a unified API gateway.

## 🏗️ Architecture

This solution consists of two microservices with enterprise-grade security and API management:

### **Auth Service** (`src/AuthService`)
- User registration and login with ASP.NET Core Identity
- JWT token generation and validation
- Password hashing with BCrypt
- User data persistence in Cosmos DB
- Secrets managed via Azure Key Vault

### **Product Service** (`src/ProductService`)
- JWT-authenticated product APIs
- CRUD operations for products
- Product data persistence in Cosmos DB
- Custom JWT middleware for authentication
- Secrets managed via Azure Key Vault

### **Shared Library** (`src/Shared`)
- Common models and utilities
- Cosmos DB service abstraction
- API response wrappers
- JWT settings configuration

### **Blazor WebAssembly Frontend** (`src/BlazorWeb`)
- Modern Material Design UI with MudBlazor 8.0
- User registration and authentication
- Product management interface
- JWT token handling and secure storage
- API integration via APIM gateway

### **Azure API Management (APIM)**
- Unified API gateway for all microservices
- Rate limiting (100 calls/minute per API)
- CORS policy management
- API documentation and developer portal
- Request/response transformation
- Gateway URL: `/auth` and `/products` paths

### **Azure Key Vault**
- Centralized secret management
- Stores: Cosmos DB keys, JWT secrets, Application Insights connection strings
- RBAC-based access control
- Managed Identity integration
- Audit logging and secret versioning

## 📋 Features

✅ **.NET 9** - Latest .NET with isolated worker model for Blazor
✅ **.NET 8** - Azure Functions with isolated worker model
✅ **Azure Functions** - Serverless compute platform
✅ **Azure Cosmos DB** - Globally distributed NoSQL database (serverless mode)
✅ **Azure API Management** - Enterprise API gateway with rate limiting
✅ **Azure Key Vault** - Secure secret management with RBAC
✅ **Managed Identity** - Passwordless authentication between Azure services
✅ **JWT Authentication** - Secure token-based authentication
✅ **Blazor WebAssembly** - Modern SPA with Material Design (MudBlazor)
✅ **Terraform** - Infrastructure as Code for Azure
✅ **Clean Architecture** - Separation of concerns and maintainability
✅ **Validation** - Request validation with Data Annotations
✅ **Error Handling** - Centralized error handling
✅ **Application Insights** - Monitoring and logging
✅ **CORS Support** - Cross-origin resource sharing
✅ **Production Ready** - Best practices and scalability

## 🚀 Prerequisites

### Required Tools
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Azure Functions Core Tools v4](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.6.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [PowerShell 7+](https://github.com/PowerShell/PowerShell) (recommended)

### Azure Subscription
- An active Azure subscription
- Appropriate permissions to create resources

## 📁 Project Structure

```
serveless/
├── src/
│   ├── AuthService/               # Authentication microservice
│   │   ├── Functions/             # HTTP trigger functions
│   │   ├── Models/                # Domain models
│   │   ├── Services/              # Business logic
│   │   ├── Program.cs             # DI configuration
│   │   └── AuthService.csproj
│   ├── ProductService/            # Product management microservice
│   │   ├── Functions/             # HTTP trigger functions
│   │   ├── Middleware/            # JWT authentication middleware
│   │   ├── Models/                # Domain models
│   │   ├── Services/              # Business logic
│   │   ├── Program.cs             # DI configuration
│   │   └── ProductService.csproj
│   ├── BlazorWeb/                 # Blazor WebAssembly frontend
│   │   ├── Pages/                 # Razor pages (Home, Login, Register, Products)
│   │   ├── Services/              # API service for HTTP calls
│   │   ├── Layout/                # App layout and navigation
│   │   ├── wwwroot/               # Static files and appsettings
│   │   └── BlazorWeb.csproj
│   └── Shared/                    # Shared library
│       ├── Infrastructure/        # Cosmos DB services
│       ├── Middleware/            # Shared middleware
│       ├── Models/                # Shared models
│       └── Shared.csproj
├── infrastructure/                # Terraform IaC
│   ├── main.tf                    # Provider configuration
│   ├── variables.tf               # Input variables
│   ├── resources.tf               # Azure resources (Functions, Cosmos)
│   ├── key-vault.tf               # Key Vault and secrets
│   ├── api-management.tf          # APIM configuration
│   ├── outputs.tf                 # Output values
│   └── terraform.tfvars           # Variable values
├── scripts/                       # Deployment scripts
│   ├── provision-infrastructure.ps1
│   ├── deploy-functions.ps1
│   ├── deploy-all.ps1
│   ├── run-local.ps1
│   ├── setup-local-azure.ps1     # Configure local dev with Azure
│   ├── configure-apim.ps1        # Configure Blazor for APIM
│   └── test-apis-simple.ps1
├── .gitignore
├── ServerlessStarter.sln
└── README.md
```

## 🛠️ Local Development Setup

### 1. Clone the Repository

```powershell
git clone <your-repo-url>
cd serveless
```

### 2. Configure Local Settings

For local development, you have three options:

**Option A: Use Cosmos DB Emulator** (Recommended for offline development)
```powershell
# Download and install Cosmos DB Emulator
# https://docs.microsoft.com/en-us/azure/cosmos-db/local-emulator

# The local.settings.json files are already configured for the emulator
```

**Option B: Use Azure Cosmos DB** (Connect to cloud resources)
```powershell
# 1. Provision Azure resources with Terraform
cd infrastructure
terraform apply -var-file="terraform-localdev.tfvars"

# 2. Auto-configure local settings
cd ..\scripts
.\setup-local-azure.ps1

# See docs/LOCAL_DEVELOPMENT_WITH_AZURE.md for details
```

**Option C: Manual Configuration**
```powershell
# Update local.settings.json in both services with your Cosmos DB credentials
```

### 3. Build the Solution

```powershell
dotnet build ServerlessStarter.sln
```

### 4. Run Locally

**Option A: Use the helper script**
```powershell
.\scripts\run-local.ps1
```

**Option B: Manual start**
```powershell
# Terminal 1 - Auth Service
cd src\AuthService
func start --port 7071

# Terminal 2 - Product Service
cd src\ProductService
func start --port 7072
```

### 5. Test the APIs

```powershell
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

## 🔗 Local Development with Azure Resources

Want to develop locally but use real Azure resources? This approach gives you:
- ✅ Real Cosmos DB (no emulator limitations)
- ✅ Application Insights integration
- ✅ Production-like environment
- ✅ Team collaboration on shared dev database

**Quick Setup:**
```powershell
# 1. Provision Azure resources
cd infrastructure
terraform apply -var-file="terraform-localdev.tfvars"

# 2. Configure local settings
cd ..\scripts
.\setup-local-azure.ps1

# 3. Run functions locally (connected to Azure)
.\run-local.ps1
```

**See detailed guide:** [docs/LOCAL_DEVELOPMENT_WITH_AZURE.md](docs/LOCAL_DEVELOPMENT_WITH_AZURE.md)
**Quick reference:** [docs/QUICK_REFERENCE_LOCAL_AZURE.md](docs/QUICK_REFERENCE_LOCAL_AZURE.md)

## ☁️ Azure Deployment

### 1. Authenticate with Azure

```powershell
az login
az account set --subscription "Your-Subscription-Name"
```

### 2. Configure Terraform Variables

```powershell
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

**Key Variables to Configure:**
- `project_name` - Your project name
- `environment` - dev, staging, or prod
- `location` - Azure region (e.g., eastus)
- `jwt_secret` - Strong secret for JWT signing (optional, auto-generated if not provided)

### 3. Deploy Infrastructure

**Option A: Interactive deployment**
```powershell
.\scripts\provision-infrastructure.ps1 -Environment dev
```

**Option B: Auto-approve deployment**
```powershell
.\scripts\provision-infrastructure.ps1 -Environment dev -AutoApprove
```

This will create:
- Resource Group
- Cosmos DB account with Users and Products containers
- Storage Account for Functions
- App Service Plan (Consumption)
- Auth Function App
- Product Function App
- Application Insights
- Log Analytics Workspace

### 4. Deploy Function Apps

```powershell
# Get the resource names from Terraform outputs
cd infrastructure
$outputs = terraform output -json | ConvertFrom-Json

# Deploy functions
cd ..\scripts
.\deploy-functions.ps1 `
    -Environment dev `
    -ResourceGroup $outputs.resource_group_name.value `
    -AuthFunctionApp $outputs.auth_function_app_name.value `
    -ProductFunctionApp $outputs.product_function_app_name.value
```

**Or use the all-in-one script:**
```powershell
.\scripts\deploy-all.ps1 -Environment dev
```

### 5. Test the Deployed APIs

```powershell
.\scripts\test-apis.ps1 `
    -BaseUrlAuth "https://func-auth-dev-xxxxx.azurewebsites.net" `
    -BaseUrlProduct "https://func-product-dev-xxxxx.azurewebsites.net"
```

## 📡 API Endpoints

### Auth Service

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "userName": "username",
  "password": "Password123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}

Response:
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "userId": "guid",
    "email": "user@example.com",
    "userName": "username",
    "expiresAt": "2025-12-18T12:00:00Z"
  }
}
```

#### Health Check
```http
GET /api/health
```

### Product Service

**Note:** All Product Service endpoints require JWT authentication via `Authorization: Bearer <token>` header.

#### Create Product
```http
POST /api/products
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "name": "Product Name",
  "description": "Product description",
  "price": 99.99,
  "category": "Electronics",
  "stock": 100
}
```

#### Get All Products
```http
GET /api/products?page=1&pageSize=10
Authorization: Bearer <jwt-token>
```

#### Get Product by ID
```http
GET /api/products/{id}
Authorization: Bearer <jwt-token>
```

#### Health Check
```http
GET /api/health
```

## 🔒 Security Considerations

### JWT Configuration
- **Secret Key**: Use a strong, randomly generated secret (min 32 characters)
- **Token Expiration**: Configure based on security requirements (default: 60 minutes)
- **HTTPS Only**: Always use HTTPS in production

### Cosmos DB
- Uses partition keys for scalability
- Primary keys stored in Function App settings (not in code)
- Consider using Managed Identity for production

### Password Security
- BCrypt hashing with automatic salt generation
- Minimum password length: 6 characters (configurable)
- Consider adding password complexity requirements

## 📊 Monitoring & Logging

### Application Insights
All functions are instrumented with Application Insights:
- Request/response logging
- Dependency tracking
- Exception tracking
- Custom metrics

**View Logs:**
```powershell
az monitor app-insights metrics show `
    --app <app-insights-name> `
    --resource-group <rg-name> `
    --metric requests/count
```

### Log Analytics
Query logs using Kusto Query Language (KQL):
```kql
traces
| where timestamp > ago(1h)
| order by timestamp desc
```

## 🧪 Testing

### Manual Testing with cURL

```powershell
# Register
$registerBody = @{
    email = "test@example.com"
    userName = "testuser"
    password = "Test123!"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://<auth-function>.azurewebsites.net/api/auth/register" `
    -Method Post -Body $registerBody -ContentType "application/json"

# Login
$loginBody = @{
    email = "test@example.com"
    password = "Test123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "https://<auth-function>.azurewebsites.net/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.data.token

# Create Product
$productBody = @{
    name = "Test Product"
    price = 99.99
    stock = 50
} | ConvertTo-Json

$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "https://<product-function>.azurewebsites.net/api/products" `
    -Method Post -Headers $headers -Body $productBody -ContentType "application/json"
```

## 🔧 Configuration Reference

### Environment Variables (Function Apps)

**Auth Service:**
- `CosmosDb__EndpointUrl` - Cosmos DB endpoint
- `CosmosDb__PrimaryKey` - Cosmos DB primary key
- `CosmosDb__DatabaseName` - Database name
- `JwtSettings__Secret` - JWT signing secret
- `JwtSettings__Issuer` - JWT issuer
- `JwtSettings__Audience` - JWT audience
- `JwtSettings__ExpirationInMinutes` - Token expiration

**Product Service:**
- Same as Auth Service

### Terraform Variables

See `infrastructure/terraform.tfvars` for all available variables.

## 🔐 Security Architecture

### Azure Key Vault Integration
All sensitive data is stored in Azure Key Vault:
- **Cosmos DB Primary Key** - Database authentication
- **Cosmos DB Connection String** - Full connection string
- **JWT Secret** - Token signing key
- **Application Insights Connection String** - Monitoring

Function Apps access secrets using **Managed Identity** with RBAC:
```
@Microsoft.KeyVault(SecretUri=${KEY_VAULT_URI}secrets/SECRET_NAME)
```

### API Management Features
- **Rate Limiting**: 100 calls/minute per API to prevent abuse
- **CORS Policies**: Configured at gateway level for consistent security
- **Request Validation**: Schema validation and request transformation
- **Monitoring**: Built-in analytics and Application Insights integration
- **Developer Portal**: Automatic API documentation

### Access Control
- Function Apps: System-assigned Managed Identity with "Key Vault Secrets User" role
- APIM: System-assigned Managed Identity with "Key Vault Secrets User" role
- Local Development: Uses local.settings.json with real Azure resources

## 🌐 API Gateway Endpoints

All APIs are exposed through Azure API Management:

**Base URL**: `https://apim-serverless-starter-dev-{suffix}.azure-api.net`

### Authentication API (`/auth`)
- `POST /auth/api/auth/register` - Register new user
- `POST /auth/api/auth/login` - Login and get JWT token

### Product API (`/products`)
- `GET /products/api/products` - List all products (requires JWT)
- `GET /products/api/products/{id}` - Get product by ID (requires JWT)
- `POST /products/api/products` - Create product (requires JWT)
- `PUT /products/api/products/{id}` - Update product (requires JWT)
- `DELETE /products/api/products/{id}` - Delete product (requires JWT)

The Blazor frontend is configured to use these APIM endpoints in production.

## 📈 Scaling Considerations

### Azure Functions
- Consumption Plan: Auto-scales based on demand (current setup)
- Premium Plan: Pre-warmed instances, VNet integration
- Dedicated Plan: Predictable pricing, more control

### Cosmos DB
- Serverless: Pay-per-request (used in this starter)
- Provisioned: Reserved throughput (RU/s)
- Autoscale: Automatically adjusts RU/s

### API Management
- Consumption Tier: Pay-per-call, auto-scaling (current setup)
- Developer Tier: Fixed capacity, no SLA
- Standard/Premium: Higher throughput, VNet integration, multi-region

## 🛡️ Production Checklist

Before going to production:

- [x] Use strong JWT secret (minimum 64 characters) - Generated by Terraform
- [x] Enable HTTPS only - Enforced by Azure Functions
- [x] Configure CORS appropriately - Managed by APIM
- [x] Set up Azure Key Vault for secrets - Implemented
- [x] Enable Managed Identity for services - Configured for Function Apps and APIM
- [x] Configure Azure API Management - Implemented with rate limiting
- [x] Set up monitoring alerts - Application Insights configured
- [x] Implement rate limiting - 100 calls/minute per API
- [ ] Configure password complexity requirements
- [ ] Set up Azure Front Door for global distribution (if needed)
- [ ] Configure backup for Cosmos DB
- [ ] Review and adjust Cosmos DB consistency level
- [ ] Set up CI/CD pipeline (GitHub Actions/Azure DevOps)
- [ ] Enable diagnostic logs for APIM
- [ ] Configure firewall rules for production
- [ ] Implement proper error handling (partially done)
- [ ] Configure custom domain for APIM
- [ ] Set up WAF (Web Application Firewall) if needed
- [ ] Add integration tests
- [ ] Document API with OpenAPI/Swagger

## 📚 Documentation

Comprehensive documentation is available in the `/docs` folder:

- **[Architecture](docs/ARCHITECTURE.md)** - System architecture diagrams and component interactions
- **[API Examples](docs/API_EXAMPLES.md)** - Complete API usage examples with curl commands
- **[Environment Configuration](docs/ENVIRONMENT_CONFIG.md)** - Multi-environment setup guide
- **[Local Development with Azure](docs/LOCAL_DEVELOPMENT_WITH_AZURE.md)** - Connect local dev to Azure resources
- **[DevOps & CI/CD](DEVOPS.md)** - Complete GitHub Actions pipeline setup
- **[Workflow Strategy](docs/WORKFLOW_STRATEGY.md)** - Branch strategy and deployment automation
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🙋 Support

For issues and questions:
- Create an issue in the [GitHub repository](https://github.com/Aminenafkha1/azure-dotnet-serverless-starter/issues)
- Check [Azure Functions documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- Review [Terraform Azure provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🔗 Useful Links

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [.NET 9 Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [Azure Cosmos DB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- [Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)

---

**Built with ❤️ using Azure, .NET, Terraform, and modern DevOps practices**

