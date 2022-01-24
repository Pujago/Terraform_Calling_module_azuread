terraform {
  // Specify the applicable backend config keys at runtime:
  # backend "azurerm" {
  #   resource_group_name  = "AZU-RGP-INTEGRATION-SBX-TF-STORAGE"
  #   storage_account_name = "intsbxstorageaccount"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }

  required_version = ">=0.14.9"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}