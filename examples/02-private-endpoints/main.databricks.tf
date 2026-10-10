# tflint-ignore-file: azurerm_resource_tag
#
# Databricks workspace.
# Below is the minimal required infrastructure to create a Databricks workspace that will support Private Endpoints.
locals {
  # Not the example's swedencentral: a Databricks workspace there never finishes deleting (since 2026-10-06), which
  # hangs the integration test's destroy. See docs/Development.md.
  databricks_location = "westeurope"
}

resource "azurerm_resource_group" "dbx_example" {
  location = local.databricks_location
  name     = "rg-github-network-module-test-dbx" # Need known name since will be used later in "cleanup helper" script.
}

module "dbx_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  # AVM modules report usage telemetry to Microsoft unless told not to
  enable_telemetry = false

  location      = local.databricks_location
  parent_id     = azurerm_resource_group.dbx_example.id
  address_space = ["10.0.1.0/24"]
  name          = "vnet-example-dbx-${random_string.suffix.result}"

  subnets = {
    public = {
      address_prefix = "10.0.1.0/25"
      name           = "dbx_public"
      delegations = [{
        name = "databricks"
        service_delegation = {
          name = "Microsoft.Databricks/workspaces"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }]
      network_security_group = {
        id = azurerm_network_security_group.dbx_nsg.id
      }
    }
    private = {
      address_prefix = "10.0.1.128/25"
      name           = "dbx_private"
      delegations = [{
        name = "databricks"
        service_delegation = {
          name = "Microsoft.Databricks/workspaces"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }]
      network_security_group = {
        id = azurerm_network_security_group.dbx_nsg.id
      }
    }
  }
}

resource "azurerm_network_security_group" "dbx_nsg" {
  location            = local.databricks_location
  name                = "nsg-example-dbx-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.dbx_example.name
}

resource "azurerm_databricks_workspace" "example" {
  location            = local.databricks_location
  name                = "dbw-example-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.dbx_example.name
  sku                 = "premium"

  custom_parameters {
    private_subnet_name                                  = module.dbx_vnet.subnets["private"].name
    private_subnet_network_security_group_association_id = module.dbx_vnet.subnets["private"].resource_id
    public_subnet_name                                   = module.dbx_vnet.subnets["public"].name
    public_subnet_network_security_group_association_id  = module.dbx_vnet.subnets["public"].resource_id
    virtual_network_id                                   = module.dbx_vnet.resource_id
  }
}
