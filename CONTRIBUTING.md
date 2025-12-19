# Contributing to Azure Serverless Starter

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project follows a Code of Conduct to ensure a welcoming environment for all contributors.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on what's best for the community
- Show empathy towards others

## Getting Started

1. **Fork the Repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone Your Fork**
   ```powershell
   git clone https://github.com/YOUR-USERNAME/serverless-starter.git
   cd serverless-starter
   ```

3. **Add Upstream Remote**
   ```powershell
   git remote add upstream https://github.com/ORIGINAL-OWNER/serverless-starter.git
   ```

4. **Set Up Development Environment**
   ```powershell
   # Install dependencies
   dotnet restore

   # Build solution
   dotnet build
   ```

## How to Contribute

### Reporting Bugs

Before submitting a bug report:
- Check existing issues to avoid duplicates
- Collect information about your environment
- Create a minimal reproduction example

**Bug Report Template:**
```markdown
**Description:**
A clear description of the bug.

**Steps to Reproduce:**
1. Step one
2. Step two
3. See error

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Environment:**
- OS: [e.g., Windows 11]
- .NET Version: [e.g., 9.0.0]
- Azure Functions Core Tools: [e.g., 4.x]

**Additional Context:**
Any other relevant information.
```

### Suggesting Features

**Feature Request Template:**
```markdown
**Feature Description:**
A clear description of the feature.

**Use Case:**
Why would this feature be useful?

**Proposed Implementation:**
How you think this could be implemented.

**Alternatives Considered:**
Alternative solutions you've considered.
```

### Contributing Code

Types of contributions we welcome:
- Bug fixes
- New features
- Documentation improvements
- Performance improvements
- Test coverage improvements

## Development Workflow

### 1. Create a Branch

```powershell
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Write clean, maintainable code
- Follow existing code style
- Add/update tests as needed
- Update documentation

### 3. Test Your Changes

```powershell
# Build solution
dotnet build

# Run locally
.\scripts\run-local.ps1

# Test APIs
.\scripts\test-apis.ps1 -BaseUrlAuth "http://localhost:7071" -BaseUrlProduct "http://localhost:7072"
```

### 4. Commit Changes

```powershell
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add user profile endpoint"
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(auth): add password reset functionality
fix(product): resolve null reference exception in GetProducts
docs(readme): update deployment instructions
refactor(shared): simplify CosmosDbService initialization
```

### 5. Push Changes

```powershell
git push origin feature/your-feature-name
```

### 6. Create Pull Request

- Go to your fork on GitHub
- Click "New Pull Request"
- Fill in the PR template
- Link related issues

## Coding Standards

### C# Style Guidelines

- Use PascalCase for public members
- Use camelCase for private fields
- Use meaningful variable names
- Keep methods small and focused
- Add XML documentation for public APIs

**Example:**
```csharp
/// <summary>
/// Authenticates a user and returns a JWT token.
/// </summary>
/// <param name="request">Login credentials</param>
/// <returns>Authentication response with token</returns>
public async Task<AuthResponse?> LoginAsync(LoginRequest request)
{
    // Implementation
}
```

### Project Structure

```
src/
├── [ServiceName]/
│   ├── Functions/        # HTTP trigger functions
│   ├── Models/           # Domain models
│   ├── Services/         # Business logic
│   ├── Middleware/       # Custom middleware
│   └── Program.cs        # DI configuration
```

### Naming Conventions

- **Functions**: Use descriptive names (e.g., `CreateProduct`, `GetUserById`)
- **Services**: Interface + Implementation (e.g., `IProductService`, `ProductService`)
- **Models**: Singular nouns (e.g., `Product`, `User`)
- **DTOs**: Suffix with Request/Response (e.g., `CreateProductRequest`)

### Error Handling

Always use try-catch in function handlers:

```csharp
[Function("ExampleFunction")]
public async Task<HttpResponseData> ExampleFunction(
    [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
{
    try
    {
        // Your code here
        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(result);
        return response;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in ExampleFunction");
        var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
        await errorResponse.WriteAsJsonAsync(
            ApiResponse<object>.ErrorResponse("An error occurred"));
        return errorResponse;
    }
}
```

### Dependency Injection

Register services in `Program.cs`:

```csharp
services.AddScoped<IYourService, YourService>();
services.AddSingleton<IYourSingletonService, YourSingletonService>();
```

## Testing Guidelines

### Manual Testing

Before submitting a PR:
1. Test locally with both services running
2. Test all modified endpoints
3. Test error scenarios
4. Test with invalid inputs

### Writing Tests (Future)

When adding unit/integration tests:
- Use xUnit framework
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies
- Test edge cases

```csharp
[Fact]
public async Task LoginAsync_WithValidCredentials_ReturnsAuthResponse()
{
    // Arrange
    var loginRequest = new LoginRequest { /* ... */ };

    // Act
    var result = await _authService.LoginAsync(loginRequest);

    // Assert
    Assert.NotNull(result);
    Assert.NotEmpty(result.Token);
}
```

## Pull Request Process

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How have you tested this?

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally

## Related Issues
Closes #issue_number
```

### Review Process

1. Automated checks must pass
2. At least one approval required
3. Address review comments
4. Maintain a clean commit history

### After Merge

- Delete your feature branch
- Sync your fork with upstream
- Celebrate your contribution! 🎉

## Documentation

### When to Update Documentation

- Adding new features
- Changing APIs
- Modifying deployment process
- Adding configuration options

### Documentation Locations

- `README.md` - Main project documentation
- `docs/API_EXAMPLES.md` - API usage examples
- `docs/TROUBLESHOOTING.md` - Common issues
- Code comments - Complex logic explanation

## Questions?

- Open a discussion on GitHub
- Check existing issues
- Review documentation

Thank you for contributing! 🙏
