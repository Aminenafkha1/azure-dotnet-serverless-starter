resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  resource_suffix = "${var.environment}-${random_string.suffix.result}"
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${local.resource_suffix}"
  location = var.location
  tags     = local.common_tags
}

# Storage Account for Function Apps
resource "azurerm_storage_account" "functions" {
  name                     = "stfunc${replace(local.resource_suffix, "-", "")}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.common_tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${var.project_name}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = local.common_tags
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "db-${var.project_name}"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Cosmos DB Containers
resource "azurerm_cosmosdb_sql_container" "users" {
  name                = "Users"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/id"
}

resource "azurerm_cosmosdb_sql_container" "products" {
  name                = "Products"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/id"
}

# App Service Plan for Function Apps
resource "azurerm_service_plan" "functions" {
  name                = "asp-${var.project_name}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.common_tags
}

# Generate JWT Secret if not provided
resource "random_password" "jwt_secret" {
  count   = var.jwt_secret == "" ? 1 : 0
  length  = 64
  special = true
}

locals {
  # Use coalesce to avoid conditional with sensitive value
  jwt_secret_value = coalesce(var.jwt_secret, try(random_password.jwt_secret[0].result, ""))
}

# Auth Function App
resource "azurerm_linux_function_app" "auth" {
  name                       = "func-auth-${local.resource_suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
    application_insights_connection_string = azurerm_application_insights.main.connection_string
    application_insights_key               = azurerm_application_insights.main.instrumentation_key
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet-isolated"
    "CosmosDb__EndpointUrl"          = azurerm_cosmosdb_account.main.endpoint
    "CosmosDb__PrimaryKey"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/CosmosDb--PrimaryKey/)"
    "CosmosDb__DatabaseName"         = azurerm_cosmosdb_sql_database.main.name
    "JwtSettings__Secret"            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/JwtSettings--Secret/)"
    "JwtSettings__Issuer"            = var.jwt_issuer
    "JwtSettings__Audience"          = var.jwt_audience
    "JwtSettings__ExpirationInMinutes" = var.jwt_expiration_minutes
    "KeyVaultName"                   = azurerm_key_vault.main.name
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Product Function App
resource "azurerm_linux_function_app" "product" {
  name                       = "func-product-${local.resource_suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
    application_insights_connection_string = azurerm_application_insights.main.connection_string
    application_insights_key               = azurerm_application_insights.main.instrumentation_key
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet-isolated"
    "CosmosDb__EndpointUrl"          = azurerm_cosmosdb_account.main.endpoint
    "CosmosDb__PrimaryKey"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/CosmosDb--PrimaryKey/)"
    "CosmosDb__DatabaseName"         = azurerm_cosmosdb_sql_database.main.name
    "JwtSettings__Secret"            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/JwtSettings--Secret/)"
    "JwtSettings__Issuer"            = var.jwt_issuer
    "JwtSettings__Audience"          = var.jwt_audience
    "JwtSettings__ExpirationInMinutes" = var.jwt_expiration_minutes
    "KeyVaultName"                   = azurerm_key_vault.main.name
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}
