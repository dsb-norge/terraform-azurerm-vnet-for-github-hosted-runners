# tflint-ignore-file: azurerm_resource_tag
#
# A caller of this module for tests/integration-test-07-migration-from-2.5.0.tftest.hcl. legacy/ uses 2.5.0 from the
# registry, the last release that named resources with Azure/naming/azurerm; current/ uses this checkout. Everything
# except module.tf must be identical between the two directories, so both describe the same infrastructure.

provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "target" {
  location = "norwayeast"
  name     = "rg-gh-migration-${random_string.suffix.result}"
}

# Target of one storage private endpoint, so a for_each naming call site is covered too.
resource "azurerm_storage_account" "target" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.target.location
  name                     = "stghmig${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.target.name
}

# Module inputs, shared by both module.tf files. The NAT gateway stays enabled (the module default) so its name and the
# public IP's are covered.
locals {
  github_database_id = "123456789"
  network_specs = {
    address_space = "10.0.0.0/24"
  }
  storage_account_private_endpoints = {
    target = {
      create_blob_pe = true
      resource_id    = azurerm_storage_account.target.id
    }
  }
  system_short_name = "gh-migration"
}

# Names of the private endpoints in the module's resource group. depends_on defers the read until the module is applied
# whenever the module has planned changes, so a replaced endpoint shows up under its new name.
data "azapi_resource_list" "private_endpoints" {
  parent_id = module.gh_vnet.resource_group_id
  type      = "Microsoft.Network/privateEndpoints@2024-05-01"
  response_export_values = {
    names = "value[].name"
  }

  depends_on = [module.gh_vnet]
}
