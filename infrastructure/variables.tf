variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "serverless"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "jwt_secret" {
  description = "JWT Secret key for token generation"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_issuer" {
  description = "JWT Issuer"
  type        = string
  default     = "https://serverless-auth.azurewebsites.net"
}

variable "apim_publisher_name" {
  description = "API Management publisher name"
  type        = string
  default     = "Serverless Starter"
}

variable "apim_publisher_email" {
  description = "API Management publisher email"
  type        = string
  default     = "admin@serverless-starter.com"
}

variable "jwt_audience" {
  description = "JWT Audience"
  type        = string
  default     = "https://serverless-api.azurewebsites.net"
}

variable "jwt_expiration_minutes" {
  description = "JWT token expiration in minutes"
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Serverless Starter"
    ManagedBy   = "Terraform"
  }
}
