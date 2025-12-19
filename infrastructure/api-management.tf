# Azure API Management
resource "azurerm_api_management" "main" {
  name                = "apim-${var.project_name}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "Consumption_0" # Free tier for development

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# API Management - Auth API
resource "azurerm_api_management_api" "auth" {
  name                = "auth-api"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Authentication API"
  path                = "auth"
  protocols           = ["https"]
  service_url         = "https://${azurerm_linux_function_app.auth.default_hostname}"

  subscription_required = false
}

# API Management - Product API
resource "azurerm_api_management_api" "product" {
  name                = "product-api"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Product API"
  path                = "products"
  protocols           = ["https"]
  service_url         = "https://${azurerm_linux_function_app.product.default_hostname}"

  subscription_required = false
}

# Auth API Operations
resource "azurerm_api_management_api_operation" "auth_register" {
  operation_id        = "register"
  api_name            = azurerm_api_management_api.auth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Register User"
  method              = "POST"
  url_template        = "/api/auth/register"
  description         = "Register a new user account"

  response {
    status_code = 200
    description = "User registered successfully"
  }

  response {
    status_code = 400
    description = "Bad request"
  }
}

resource "azurerm_api_management_api_operation" "auth_login" {
  operation_id        = "login"
  api_name            = azurerm_api_management_api.auth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Login User"
  method              = "POST"
  url_template        = "/api/auth/login"
  description         = "Authenticate user and get JWT token"

  response {
    status_code = 200
    description = "Login successful"
  }

  response {
    status_code = 401
    description = "Unauthorized"
  }
}

# Product API Operations
resource "azurerm_api_management_api_operation" "product_list" {
  operation_id        = "list-products"
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "List Products"
  method              = "GET"
  url_template        = "/api/products"
  description         = "Get all products"

  response {
    status_code = 200
    description = "Success"
  }
}

resource "azurerm_api_management_api_operation" "product_get" {
  operation_id        = "get-product"
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Product"
  method              = "GET"
  url_template        = "/api/products/{id}"
  description         = "Get product by ID"

  template_parameter {
    name     = "id"
    required = true
    type     = "string"
  }

  response {
    status_code = 200
    description = "Success"
  }

  response {
    status_code = 404
    description = "Not found"
  }
}

resource "azurerm_api_management_api_operation" "product_create" {
  operation_id        = "create-product"
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Create Product"
  method              = "POST"
  url_template        = "/api/products"
  description         = "Create a new product"

  response {
    status_code = 201
    description = "Created"
  }

  response {
    status_code = 400
    description = "Bad request"
  }
}

resource "azurerm_api_management_api_operation" "product_update" {
  operation_id        = "update-product"
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Update Product"
  method              = "PUT"
  url_template        = "/api/products/{id}"
  description         = "Update an existing product"

  template_parameter {
    name     = "id"
    required = true
    type     = "string"
  }

  response {
    status_code = 200
    description = "Success"
  }

  response {
    status_code = 404
    description = "Not found"
  }
}

resource "azurerm_api_management_api_operation" "product_delete" {
  operation_id        = "delete-product"
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Delete Product"
  method              = "DELETE"
  url_template        = "/api/products/{id}"
  description         = "Delete a product"

  template_parameter {
    name     = "id"
    required = true
    type     = "string"
  }

  response {
    status_code = 204
    description = "No content"
  }

  response {
    status_code = 404
    description = "Not found"
  }
}

# CORS Policy for both APIs
resource "azurerm_api_management_api_policy" "auth_cors" {
  api_name            = azurerm_api_management_api.auth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <rate-limit calls="100" renewal-period="60" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

resource "azurerm_api_management_api_policy" "product_cors" {
  api_name            = azurerm_api_management_api.product.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <rate-limit calls="100" renewal-period="60" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

# Grant APIM access to Key Vault
resource "azurerm_role_assignment" "apim_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.main.identity[0].principal_id
}
