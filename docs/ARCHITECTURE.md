# Architecture Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                            │
│         (Blazor WebAssembly, Mobile Apps, SPAs)                 │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ HTTPS
                  ▼
         ┌────────────────────┐
         │  Azure API         │
         │  Management (APIM) │
         │  - Rate Limiting   │
         │  - CORS Policies   │
         │  - Monitoring      │
         └─────────┬──────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
┌───▼──────────┐          ┌───────▼─────────┐
│ Auth Service │          │ Product Service │
│ (Port 7071)  │          │   (Port 7072)   │
│              │          │                 │
│ - Register   │          │ - Create Product│
│ - Login      │          │ - Get Products  │
│ - JWT Gen    │◄─────────┤ - Get by ID     │
└──────┬───────┘   Verify │                 │
       │           JWT    └────────┬────────┘
       │                           │
       │                           │
       └────────────┬──────────────┘
                    │
            ┌───────▼────────┐
            │  Cosmos DB     │
            │  (Serverless)  │
            │                │
            │  ┌──────────┐  │
            │  │  Users   │  │
            │  └──────────┘  │
            │  ┌──────────┐  │
            │  │ Products │  │
            │  └──────────┘  │
            └────────────────┘
```

## Authentication Flow

```
┌──────┐                 ┌────────────┐              ┌──────────┐
│Client│                 │Auth Service│              │Cosmos DB │
└──┬───┘                 └─────┬──────┘              └────┬─────┘
   │                           │                          │
   │  POST /auth/register      │                          │
   ├──────────────────────────►│                          │
   │  (email, password, etc)   │                          │
   │                           │  Hash Password           │
   │                           ├──────────┐               │
   │                           │          │               │
   │                           │◄─────────┘               │
   │                           │                          │
   │                           │  Create User             │
   │                           ├─────────────────────────►│
   │                           │                          │
   │                           │◄─────────────────────────┤
   │  201 Created              │  User Created            │
   │◄──────────────────────────┤                          │
   │                           │                          │
   │  POST /auth/login         │                          │
   ├──────────────────────────►│                          │
   │  (email, password)        │                          │
   │                           │  Get User by Email       │
   │                           ├─────────────────────────►│
   │                           │                          │
   │                           │◄─────────────────────────┤
   │                           │  User Data               │
   │                           │                          │
   │                           │  Verify Password         │
   │                           ├──────────┐               │
   │                           │          │               │
   │                           │◄─────────┘               │
   │                           │                          │
   │                           │  Generate JWT            │
   │                           ├──────────┐               │
   │                           │          │               │
   │                           │◄─────────┘               │
   │  200 OK + JWT Token       │                          │
   │◄──────────────────────────┤                          │
   │                           │                          │
```

## Product Operations Flow

```
┌──────┐         ┌───────────────┐         ┌──────────┐
│Client│         │Product Service│         │Cosmos DB │
└──┬───┘         └───────┬───────┘         └────┬─────┘
   │                     │                      │
   │  POST /products     │                      │
   ├────────────────────►│                      │
   │  Authorization:     │                      │
   │  Bearer <JWT>       │                      │
   │                     │  Validate JWT        │
   │                     ├───────────┐          │
   │                     │           │          │
   │                     │◄──────────┘          │
   │                     │  JWT Valid           │
   │                     │                      │
   │                     │  Extract User ID     │
   │                     ├───────────┐          │
   │                     │           │          │
   │                     │◄──────────┘          │
   │                     │                      │
   │                     │  Create Product      │
   │                     ├─────────────────────►│
   │                     │  (with user ID)      │
   │                     │                      │
   │                     │◄─────────────────────┤
   │  201 Created        │  Product Created     │
   │◄────────────────────┤                      │
   │  Product Data       │                      │
   │                     │                      │
   │  GET /products      │                      │
   ├────────────────────►│                      │
   │  Authorization:     │                      │
   │  Bearer <JWT>       │                      │
   │                     │  Validate JWT        │
   │                     ├───────────┐          │
   │                     │           │          │
   │                     │◄──────────┘          │
   │                     │                      │
   │                     │  Query Products      │
   │                     ├─────────────────────►│
   │                     │  (with pagination)   │
   │                     │                      │
   │                     │◄─────────────────────┤
   │  200 OK             │  Product List        │
   │◄────────────────────┤                      │
   │  Products[]         │                      │
   │                     │                      │
```

## Azure Infrastructure

```
┌───────────────────────────────────────────────────────────────┐
│                     Azure Subscription                        │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Resource Group                             │ │
│  │                                                         │ │
│  │  ┌────────────────┐         ┌────────────────┐        │ │
│  │  │ Auth Function  │         │Product Function│        │ │
│  │  │      App       │         │      App       │        │ │
│  │  │   (Linux)      │         │   (Linux)      │        │ │
│  │  └───────┬────────┘         └───────┬────────┘        │ │
│  │          │                          │                 │ │
│  │          └────────────┬─────────────┘                 │ │
│  │                       │                               │ │
│  │          ┌────────────▼─────────────┐                 │ │
│  │          │   App Service Plan       │                 │ │
│  │          │   (Consumption Y1)       │                 │ │
│  │          └──────────────────────────┘                 │ │
│  │                                                        │ │
│  │          ┌──────────────────────────┐                 │ │
│  │          │   Storage Account        │                 │ │
│  │          │   (Functions Storage)    │                 │ │
│  │          └──────────────────────────┘                 │ │
│  │                                                        │ │
│  │          ┌──────────────────────────┐                 │ │
│  │          │   Cosmos DB Account      │                 │ │
│  │          │   (Serverless)           │                 │ │
│  │          │                          │                 │ │
│  │          │  ┌────────────────────┐  │                 │ │
│  │          │  │ Database           │  │                 │ │
│  │          │  │                    │  │                 │ │
│  │          │  │ ┌───────────────┐  │  │                 │ │
│  │          │  │ │Users Container│  │  │                 │ │
│  │          │  │ └───────────────┘  │  │                 │ │
│  │          │  │ ┌───────────────┐  │  │                 │ │
│  │          │  │ │Products Cont. │  │  │                 │ │
│  │          │  │ └───────────────┘  │  │                 │ │
│  │          │  └────────────────────┘  │                 │ │
│  │          └──────────────────────────┘                 │ │
│  │                                                        │ │
│  │          ┌──────────────────────────┐                 │ │
│  │          │  Application Insights    │                 │ │
│  │          │  (Monitoring & Logs)     │                 │ │
│  │          └──────────────────────────┘                 │ │
│  │                       │                               │ │
│  │          ┌────────────▼─────────────┐                 │ │
│  │          │  Log Analytics           │                 │ │
│  │          │  Workspace               │                 │ │
│  │          └──────────────────────────┘                 │ │
│  │                                                        │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

## Data Model

### Users Container

```
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "userName": "username",
  "passwordHash": "$2a$11$...",
  "firstName": "John",
  "lastName": "Doe",
  "createdAt": "2025-12-18T10:00:00Z",
  "updatedAt": "2025-12-18T10:00:00Z",
  "isActive": true
}

Partition Key: /id
```

### Products Container

```
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Product Name",
  "description": "Product description",
  "price": 99.99,
  "category": "Electronics",
  "stock": 100,
  "isActive": true,
  "createdBy": "550e8400-e29b-41d4-a716-446655440000",
  "createdAt": "2025-12-18T10:30:00Z",
  "updatedAt": "2025-12-18T10:30:00Z"
}

Partition Key: /id
```

## JWT Token Structure

```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "username",
  "nameid": "550e8400-e29b-41d4-a716-446655440000",
  "jti": "unique-token-id",
  "exp": 1702906800,
  "iss": "https://serverless-auth.azurewebsites.net",
  "aud": "https://serverless-api.azurewebsites.net"
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

## Deployment Pipeline

```
Developer
    │
    │ git push
    │
    ▼
┌─────────────┐
│  Git Repo   │
└──────┬──────┘
       │
       │ (Manual/CI/CD)
       │
       ▼
┌─────────────┐
│  Terraform  │────► Infrastructure
└──────┬──────┘       Provisioning
       │
       │ terraform apply
       │
       ▼
┌─────────────────────┐
│  Azure Resources    │
│  - Resource Group   │
│  - Cosmos DB        │
│  - Function Apps    │
│  - Storage          │
│  - App Insights     │
└──────┬──────────────┘
       │
       │ Deploy Code
       │
       ▼
┌─────────────┐
│ Build & Zip │
└──────┬──────┘
       │
       │ az functionapp deployment
       │
       ▼
┌─────────────────┐
│ Function Apps   │
│  - Auth Service │
│  - Product Svc  │
└─────────────────┘
```

## Security Layers

```
┌──────────────────────────────────────────┐
│         External Layer                   │
│  - HTTPS Only                            │
│  - CORS Configuration                    │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│      Authentication Layer                │
│  - JWT Validation                        │
│  - Token Expiration Check                │
│  - Signature Verification                │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│      Application Layer                   │
│  - Input Validation                      │
│  - Business Logic                        │
│  - Error Handling                        │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│         Data Layer                       │
│  - Cosmos DB Authentication              │
│  - Partition Key Validation              │
│  - Connection String Security            │
└──────────────────────────────────────────┘
```

## Monitoring Flow

```
┌──────────────┐         ┌──────────────┐
│Auth Function │         │Product Func  │
└──────┬───────┘         └──────┬───────┘
       │                        │
       │ Telemetry              │ Telemetry
       │                        │
       └────────┬───────────────┘
                │
                ▼
       ┌────────────────┐
       │  App Insights  │
       └────────┬───────┘
                │
                │ Aggregation
                │
                ▼
       ┌────────────────┐
       │ Log Analytics  │
       │   Workspace    │
       └────────┬───────┘
                │
                │ Query/Alert
                │
                ▼
       ┌────────────────┐
       │  Azure Portal  │
       │   Dashboards   │
       └────────────────┘
```

## Local Development Setup

```
Developer Machine
│
├─ .NET 9 SDK
├─ Azure Functions Core Tools
├─ VS Code / Visual Studio
│
├─ Terminal 1
│  └─ Auth Service (Port 7071)
│     └─ func start
│
├─ Terminal 2
│  └─ Product Service (Port 7072)
│     └─ func start
│
└─ Cosmos DB Emulator (Port 8081)
   └─ Local Database
      ├─ Users Container
      └─ Products Container
```
