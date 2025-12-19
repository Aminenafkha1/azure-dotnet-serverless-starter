output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "auth_function_app_name" {
  description = "The name of the Auth Function App"
  value       = azurerm_linux_function_app.auth.name
}

output "product_function_app_name" {
  description = "The name of the Product Function App"
  value       = azurerm_linux_function_app.product.name
}

output "auth_function_app_default_hostname" {
  description = "The default hostname of the Auth Function App"
  value       = azurerm_linux_function_app.auth.default_hostname
}

output "product_function_app_default_hostname" {
  description = "The default hostname of the Product Function App"
  value       = azurerm_linux_function_app.product.default_hostname
}

output "cosmosdb_endpoint" {
  description = "The endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_database_name" {
  description = "The name of the Cosmos DB database"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Static Web App outputs removed - resource not supported in current azurerm provider version
# Blazor app can be deployed to Azure Storage Static Website or Azure App Service

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "apim_gateway_url" {
  description = "The gateway URL of API Management"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_name" {
  description = "The name of API Management"
  value       = azurerm_api_management.main.name
}
