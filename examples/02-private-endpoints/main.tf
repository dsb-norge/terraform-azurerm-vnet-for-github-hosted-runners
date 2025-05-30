provider "azurerm" {
  features {
    key_vault {
      # to clean up properly after integration testing
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

# create two sets of unique names
module "names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = toset(["1", "2"])

  suffix = ["example", each.value]
}

resource "azurerm_resource_group" "example" {
  name = module.names["1"].resource_group.name_unique

  # non-standard location, passed to the module further down
  location = "northeurope"
}

data "azurerm_client_config" "current" {}

# two key vaults
resource "azurerm_key_vault" "example" {
  for_each = module.names

  name                       = each.value.key_vault.name_unique
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7 # shortest possible
  purge_protection_enabled   = false
  sku_name                   = "standard"
}

# two storage accounts
resource "azurerm_storage_account" "example" {
  for_each = module.names

  name                     = each.value.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# one vnet with private endpoints for key vaults and storage accounts
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

  # other inputs
  location          = azurerm_resource_group.example.location
  system_name       = "github-runner-example"
  system_short_name = "gh-example"

  # key vault private endpoints
  key_vault_private_endpoints = {
    kv1 = {
      resource_id = azurerm_key_vault.example["1"].id
    }
    kv2 = {
      resource_id = azurerm_key_vault.example["2"].id
  } }

  # storage account private endpoints
  storage_account_private_endpoints = {
    sa1 = {
      resource_id = azurerm_storage_account.example["1"].id

      # only the privatelink.blob.core.windows.net DNS zone will be created
      create_blob_pe = true
    }
    sa2 = {
      resource_id = azurerm_storage_account.example["2"].id

      # all privatelink DNS zones will be created
      create_blob_pe  = true
      create_file_pe  = true
      create_queue_pe = true
      create_table_pe = true
      create_web_pe   = true
      create_dfs_pe   = true
  } }

  # resource tags can be provided
  tags = {
    Environment = "Example"
    Project     = "GitHub Runner Integration"
    Owner       = "DevOps Team"
  }
}
