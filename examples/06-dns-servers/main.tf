# tflint-ignore-file: azurerm_resource_tag
#
# Example: Custom DNS servers with BYO private DNS zones
#
# This example demonstrates:
#   - Configuring custom DNS servers on the VNet (e.g. Azure Firewall DNS proxy)
#   - Using BYO (bring-your-own) private DNS zones for storage private endpoints
#     instead of having the module create and manage them
#
provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

# unique names to avoid name collisions during integration testing
module "names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix = ["example"]
}

# create a resource group for this example's supporting resources
resource "azurerm_resource_group" "example" {
  location = "norwayeast"
  name     = module.names.resource_group.name_unique
}

# create a storage account to demonstrate private endpoint with BYO DNS zone
resource "azurerm_storage_account" "example" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.example.location
  name                     = module.names.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.example.name
}

# create a BYO private DNS zone for blob (simulating a centrally managed zone)
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

# call the module with custom DNS servers and BYO DNS zone
module "gh_vnet" {
  source = "../../"

  # required inputs
  github_database_id = "123456789"
  network_specs = {
    address_space = "10.0.0.0/24"
    tags = {
      ExampleIPAMTag = "IPAM-reservation-ID"
    }
  }

  # custom DNS servers (e.g. Azure Firewall DNS proxy in a hub network)
  dns_servers = ["10.0.0.4"]

  # storage account with blob private endpoint using BYO DNS zone
  storage_account_private_endpoints = {
    example = {
      resource_id    = azurerm_storage_account.example.id
      create_blob_pe = true
    }
  }

  # use the BYO DNS zone for blob instead of module-created one
  storage_private_dns_zone_ids = {
    blob = azurerm_private_dns_zone.blob.id
  }
}
