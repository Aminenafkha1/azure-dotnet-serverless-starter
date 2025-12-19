# Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "kv-${local.resource_suffix}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Store Cosmos DB connection string
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "CosmosDb--ConnectionString"
  value        = "AccountEndpoint=${azurerm_cosmosdb_account.main.endpoint};AccountKey=${azurerm_cosmosdb_account.main.primary_key};"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}

# Store Cosmos DB primary key
resource "azurerm_key_vault_secret" "cosmos_primary_key" {
  name         = "CosmosDb--PrimaryKey"
  value        = azurerm_cosmosdb_account.main.primary_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}

# Store JWT Secret
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "JwtSettings--Secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}

# Store Application Insights Connection String
resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "ApplicationInsights--ConnectionString"
  value        = azurerm_application_insights.main.connection_string
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Grant Key Vault Administrator role to current user/service principal
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant Key Vault Secrets User role to Auth Function
resource "azurerm_role_assignment" "auth_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.auth.identity[0].principal_id
}

# Grant Key Vault Secrets User role to Product Function
resource "azurerm_role_assignment" "product_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.product.identity[0].principal_id
}
