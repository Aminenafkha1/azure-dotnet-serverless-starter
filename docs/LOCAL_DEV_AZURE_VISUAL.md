# Local Development with Azure Connection - Visual Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                   YOUR LOCAL MACHINE                            │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐              │
│  │  Auth Service   │         │ Product Service │              │
│  │  localhost:7071 │         │  localhost:7072 │              │
│  │                 │         │                 │              │
│  │  - Register     │         │  - Products     │              │
│  │  - Login        │         │  - CRUD Ops     │              │
│  │  - JWT Gen      │         │  - JWT Auth     │              │
│  └────────┬────────┘         └────────┬────────┘              │
│           │                           │                        │
│           │  HTTPS Connection         │                        │
│           │  (via Azure SDK)          │                        │
└───────────┼───────────────────────────┼────────────────────────┘
            │                           │
            │                           │
     ┌──────┴───────────────────────────┴──────┐
     │         INTERNET                        │
     └──────┬───────────────────────────┬──────┘
            │                           │
            │                           │
┌───────────▼───────────────────────────▼────────────────────────┐
│                      AZURE CLOUD                               │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Resource Group (localdev)                  │  │
│  │                                                         │  │
│  │  ┌──────────────────────────┐                          │  │
│  │  │   Cosmos DB Account      │                          │  │
│  │  │   (Serverless)           │                          │  │
│  │  │                          │                          │  │
│  │  │  ┌────────────────────┐  │                          │  │
│  │  │  │ Database           │  │                          │  │
│  │  │  │                    │  │                          │  │
│  │  │  │ ┌───────────────┐  │  │                          │  │
│  │  │  │ │Users Container│  │  │                          │  │
│  │  │  │ │  - User docs  │  │  │◄─── Auth writes here    │  │
│  │  │  │ │  - Auth data  │  │  │                          │  │
│  │  │  │ └───────────────┘  │  │                          │  │
│  │  │  │                    │  │                          │  │
│  │  │  │ ┌───────────────┐  │  │                          │  │
│  │  │  │ │Products Cont. │  │  │                          │  │
│  │  │  │ │  - Product    │  │  │◄─── Product writes here │  │
│  │  │  │ │    documents  │  │  │                          │  │
│  │  │  │ └───────────────┘  │  │                          │  │
│  │  │  └────────────────────┘  │                          │  │
│  │  └──────────────────────────┘                          │  │
│  │                                                         │  │
│  │  ┌──────────────────────────┐                          │  │
│  │  │  Application Insights    │                          │  │
│  │  │  - Telemetry             │◄─── Both services send  │  │
│  │  │  - Logs                  │     telemetry            │  │
│  │  │  - Metrics               │                          │  │
│  │  └──────────────────────────┘                          │  │
│  │                                                         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Setup Process Flow

```
┌─────────────┐
│   Step 1    │
│ Run Terraform│
│   locally   │
└──────┬──────┘
       │
       │ terraform apply -var-file="terraform-localdev.tfvars"
       │
       ▼
┌─────────────────┐
│  Terraform      │
│  Provisions:    │
│  - Cosmos DB    │
│  - App Insights │
│  - Storage      │
└──────┬──────────┘
       │
       │ Creates resources in Azure
       │
       ▼
┌─────────────────┐
│  Azure Resources│
│    Created      │
└──────┬──────────┘
       │
       │ Terraform outputs connection details
       │
       ▼
┌─────────────────┐
│   Step 2        │
│ Run setup       │
│    script       │
└──────┬──────────┘
       │
       │ .\setup-local-azure.ps1
       │
       ▼
┌─────────────────┐
│  Script:        │
│  1. Gets outputs│
│  2. Gets keys   │
│  3. Updates     │
│     settings    │
└──────┬──────────┘
       │
       │ Writes to local.settings.json
       │
       ▼
┌─────────────────┐
│  local.settings │
│      .json      │
│   CONFIGURED    │
└──────┬──────────┘
       │
       │ Functions read settings on start
       │
       ▼
┌─────────────────┐
│   Step 3        │
│ Run Functions   │
│    Locally      │
└──────┬──────────┘
       │
       │ func start
       │
       ▼
┌─────────────────┐
│  Functions      │
│  Running on     │
│  localhost      │
│  Connected to   │
│     Azure       │
└─────────────────┘
```

## Data Flow Example: User Registration

```
Developer      Local Function      Azure Cosmos DB      Azure Portal
    │                │                    │                   │
    │  POST          │                    │                   │
    │  /register     │                    │                   │
    ├───────────────►│                    │                   │
    │                │                    │                   │
    │                │  Hash Password     │                   │
    │                ├────────┐           │                   │
    │                │        │           │                   │
    │                │◄───────┘           │                   │
    │                │                    │                   │
    │                │  CREATE User       │                   │
    │                │  (via Azure SDK)   │                   │
    │                ├───────────────────►│                   │
    │                │  HTTPS             │                   │
    │                │                    │  Store in Users   │
    │                │                    │  container        │
    │                │                    ├───────┐           │
    │                │                    │       │           │
    │                │                    │◄──────┘           │
    │                │                    │                   │
    │                │◄───────────────────┤                   │
    │                │  User Created      │                   │
    │                │                    │                   │
    │                │  Send Telemetry    │                   │
    │                │  to App Insights   │                   │
    │                ├────────────────────┼──────────────────►│
    │                │                    │                   │
    │◄───────────────┤                    │                   │
    │  200 OK        │                    │                   │
    │  User Data     │                    │                   │
    │                │                    │                   │
    │                                     │                   │
    └──────────────────────────────────► Query Data ◄────────┘
                                          in Portal
```

## Connection Details in local.settings.json

```
┌─────────────────────────────────────────────────────────────┐
│  src/AuthService/local.settings.json                        │
│  src/ProductService/local.settings.json                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  "CosmosDb__EndpointUrl":                                   │
│    "https://cosmos-serverless-localdev-xxx.documents.      │
│     azure.com:443/"                                         │
│         │                                                   │
│         └──► Points to your Azure Cosmos DB account        │
│                                                             │
│  "CosmosDb__PrimaryKey":                                    │
│    "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9..."     │
│         │                                                   │
│         └──► Authentication key for Cosmos DB              │
│                                                             │
│  "CosmosDb__DatabaseName":                                  │
│    "db-serverless"                                          │
│         │                                                   │
│         └──► Which database to use                         │
│                                                             │
│  "APPLICATIONINSIGHTS_CONNECTION_STRING":                   │
│    "InstrumentationKey=xxx;IngestionEndpoint=https://..."   │
│         │                                                   │
│         └──► Where to send telemetry                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## What Happens When You Run Locally

```
Your Machine                          Azure Cloud
─────────────────────────────────────────────────────────────

1. You start Auth Service
   func start --port 7071
      │
      ├─► Reads local.settings.json
      │   Gets Cosmos DB endpoint & key
      │
      ├─► Creates CosmosClient
      │   with Azure SDK
      │
      └─► Connects to Azure
          ├─► Establishes HTTPS connection
          └─► Authenticates with primary key
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │  Cosmos DB   │
                                    │   Account    │
                                    └──────────────┘

2. User hits your API
   POST http://localhost:7071/api/auth/register
      │
      └─► Auth Service processes
          ├─► Hashes password (local)
          │
          └─► Calls Cosmos DB
              Container.CreateItemAsync(user)
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Users        │
                                    │ Container    │
                                    │ + New User   │
                                    └──────────────┘

3. Telemetry sent
      │
      └─► TelemetryClient.TrackEvent()
          Sends over HTTPS
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Application  │
                                    │  Insights    │
                                    │ + New Trace  │
                                    └──────────────┘
```

## Benefits Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                WITHOUT Azure Connection                     │
├─────────────────────────────────────────────────────────────┤
│  ✗ Limited Cosmos DB Emulator features                      │
│  ✗ No Application Insights                                  │
│  ✗ No team data sharing                                     │
│  ✗ Different from production                                │
│  ✗ Emulator bugs/quirks                                     │
└─────────────────────────────────────────────────────────────┘

                          VS

┌─────────────────────────────────────────────────────────────┐
│                 WITH Azure Connection                       │
├─────────────────────────────────────────────────────────────┤
│  ✓ Full Cosmos DB features                                  │
│  ✓ Real-time Application Insights                           │
│  ✓ Team shares development data                             │
│  ✓ Closer to production environment                         │
│  ✓ Test Azure-specific features                             │
│  ✓ Low cost (~$1-5/month)                                   │
└─────────────────────────────────────────────────────────────┘
```

## Team Collaboration Scenario

```
Team Member A          Shared Azure          Team Member B
   (Your PC)          Cosmos DB             (Teammate PC)
      │                   │                      │
      │                   │                      │
      │  Register User    │                      │
      │  "alice@..."      │                      │
      ├──────────────────►│                      │
      │                   │                      │
      │                   │◄─────────────────────┤
      │                   │  Query Users         │
      │                   │                      │
      │                   ├─────────────────────►│
      │                   │  Returns:            │
      │                   │  - alice@...         │
      │                   │                      │
      │  Login as Alice   │                      │
      ├──────────────────►│                      │
      │  (works!)         │                      │
      │                   │                      │
      │                   │                      │
   Both developers see the same data in         │
   Azure Portal Data Explorer                   │
```

## Cost Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│              Monthly Cost Estimate (Low Usage)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Cosmos DB (Serverless)                                     │
│  ├─ Storage: ~0.25 GB × $0.25/GB    = $0.06/month          │
│  └─ Operations: ~50K RUs × $0.25/M  = $0.01/month          │
│                                                             │
│  Application Insights                                       │
│  └─ < 5 GB data ingestion           = FREE                 │
│                                                             │
│  Storage Account                                            │
│  └─ Minimal usage                   = $0.02/month          │
│                                                             │
│  Function Apps (not deployed)       = $0                   │
│                                                             │
│  ─────────────────────────────────────────────────────     │
│  TOTAL:                             ≈ $0.10-$2.00/month    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Note: Actual costs may vary. Monitor in Azure Cost Management.
```

## Security Considerations

```
┌─────────────────────────────────────────────────────────────┐
│                  Security Layers                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Network Security                                        │
│     ├─► HTTPS only (TLS 1.2+)                               │
│     └─► Azure network security                              │
│                                                             │
│  2. Authentication                                          │
│     ├─► Cosmos DB primary key (in local.settings.json)     │
│     └─► Never commit local.settings.json to git            │
│                                                             │
│  3. Access Control                                          │
│     ├─► Azure RBAC for resource access                     │
│     └─► Your Azure account credentials                     │
│                                                             │
│  4. Data Protection                                         │
│     ├─► Cosmos DB encryption at rest                       │
│     └─► Encryption in transit (HTTPS)                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘

⚠️  IMPORTANT: Never commit local.settings.json to version control
    It contains sensitive connection strings and keys!
```

## Monitoring Your Local Dev Activity

```
Azure Portal
    │
    ├─► Cosmos DB
    │   ├─► Data Explorer
    │   │   └─► See all data created locally
    │   │
    │   └─► Metrics
    │       └─► Request rate, latency, etc.
    │
    └─► Application Insights
        ├─► Transaction search
        │   └─► See requests from your local machine
        │
        ├─► Failures
        │   └─► Any errors/exceptions
        │
        └─► Performance
            └─► Response times
```

## Quick Reference Commands

```bash
# Setup (one time)
terraform apply -var-file="terraform-localdev.tfvars"
.\setup-local-azure.ps1

# Daily workflow
.\run-local.ps1

# View data
# Go to portal.azure.com → Cosmos DB → Data Explorer

# Cleanup (when done)
terraform destroy -var-file="terraform-localdev.tfvars"
```
