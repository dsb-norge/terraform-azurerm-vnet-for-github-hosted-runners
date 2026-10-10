terraform {
  required_version = "~> 1.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.20.0, < 5.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.12.0, < 3.0.0"
    }
  }
}
