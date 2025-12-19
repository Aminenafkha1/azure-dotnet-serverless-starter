# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-18

### Added

#### Core Infrastructure
- Complete Terraform infrastructure for Azure deployment
- Resource group provisioning
- Azure Cosmos DB (serverless) with Users and Products containers
- Azure Function Apps (Consumption plan) for Auth and Product services
- Storage Account for Function Apps
- Application Insights for monitoring
- Log Analytics Workspace for log aggregation
- Managed Identity support for Function Apps

#### Auth Service
- User registration endpoint with validation
- User login endpoint with JWT generation
- BCrypt password hashing
- Email-based authentication
- User data persistence in Cosmos DB
- Health check endpoint
- Comprehensive error handling
- Request validation with Data Annotations

#### Product Service
- Create product endpoint (authenticated)
- Get all products with pagination (authenticated)
- Get product by ID endpoint (authenticated)
- JWT authentication middleware
- Product data persistence in Cosmos DB
- Health check endpoint
- Comprehensive error handling
- Request validation with Data Annotations

#### Shared Library
- Common API response wrapper
- JWT settings configuration model
- Cosmos DB settings configuration model
- Cosmos DB service abstraction
- Exception handling middleware
- Reusable infrastructure components

#### Development Tools
- PowerShell deployment scripts
  - Complete deployment script (`deploy-all.ps1`)
  - Infrastructure provisioning script (`provision-infrastructure.ps1`)
  - Function deployment script (`deploy-functions.ps1`)
  - Local development script (`run-local.ps1`)
  - API testing script (`test-apis.ps1`)
- VS Code configuration
  - Workspace settings
  - Recommended extensions
- HTTP test requests file for API testing

#### Documentation
- Comprehensive README with setup instructions
- Quick start guide for rapid onboarding
- API examples with cURL and PowerShell samples
- Troubleshooting guide for common issues
- Architecture diagrams and documentation
- Contributing guidelines
- Project summary
- MIT License

#### Configuration
- `.editorconfig` for consistent code formatting
- `.gitignore` for version control
- `global.json` for .NET SDK version management
- `Directory.Build.props` for common project properties
- Environment variable templates
- Terraform variable examples
- Local settings for development

### Security Features
- JWT token-based authentication
- BCrypt password hashing with automatic salt
- HTTPS enforcement (production)
- CORS configuration
- Input validation
- Secure configuration management
- Environment-based secrets

### Developer Experience
- Clean architecture with separation of concerns
- Dependency injection throughout
- Async/await patterns
- Comprehensive logging
- Error handling with meaningful messages
- Type-safe models
- Interface-based design

### Production Readiness
- Auto-scaling serverless architecture
- Application Insights integration
- Health check endpoints
- Structured logging
- Error tracking
- Performance monitoring
- Cost-optimized infrastructure

## [Unreleased]

### Planned Features
- CI/CD pipeline templates (GitHub Actions, Azure DevOps)
- Unit test projects
- Integration test projects
- API versioning
- Rate limiting
- Refresh token functionality
- User roles and permissions
- Email verification
- Password reset functionality
- API documentation with Swagger/OpenAPI
- Azure Key Vault integration
- Additional authentication providers (OAuth, Azure AD)
- Docker support
- Kubernetes deployment templates
- GraphQL API support
- Message queue integration (Azure Service Bus/Event Grid)

---

## Version History

### Versioning Strategy

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

### Release Types

- **Stable Releases**: Production-ready versions (e.g., 1.0.0, 1.1.0)
- **Pre-releases**: Beta versions for testing (e.g., 1.1.0-beta.1)
- **Development**: Ongoing work in feature branches

---

## How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- Reporting bugs
- Suggesting features
- Submitting pull requests
- Code style guidelines

---

## Credits

Built with:
- [.NET 9](https://dotnet.microsoft.com/)
- [Azure Functions](https://azure.microsoft.com/services/functions/)
- [Azure Cosmos DB](https://azure.microsoft.com/services/cosmos-db/)
- [Terraform](https://www.terraform.io/)
- [BCrypt.NET](https://github.com/BcryptNet/bcrypt.net)

---

**Note**: This changelog will be updated with each release. For the latest changes, see the [commit history](../../commits/).
