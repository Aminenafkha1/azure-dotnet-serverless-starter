# Remote State Configuration for Production Use
# This file configures Terraform to store state in Azure Storage
# ensuring team collaboration and state locking

terraform {
  backend "azurerm" {
    # These values should be provided via backend-config during init
    # terraform init -backend-config="resource_group_name=rg-terraform-state" ...

    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "sttfstate<random>"
    # container_name       = "tfstate"
    # key                  = "dev.terraform.tfstate"

    use_azuread_auth = true
  }
}

# For local development, you can comment out the backend block above
# and Terraform will use local state file (terraform.tfstate)
