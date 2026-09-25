terraform {
  required_providers {
    # Same constraint as Azure/naming/azurerm 0.4.3, which this module replaces.
    # Keeping it identical leaves the constraints recorded in callers' lock
    # files unchanged.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.2"
    }
  }
}
