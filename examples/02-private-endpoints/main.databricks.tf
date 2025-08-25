# Databricks workspace.
# Below is the minimal required infrastructure to create a Databricks workspace that will support Private Endpoints.
locals {
  databricks_location = "swedencentral"
}

resource "azurerm_resource_group" "dbx_example" {
  name     = "rg-github-network-module-test-dbx" # Need known name since will be used later in "cleanup helper" script.
  location = local.databricks_location
}

module "dbx_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  location            = local.databricks_location
  resource_group_name = azurerm_resource_group.dbx_example.name
  address_space       = ["10.0.1.0/24"]
  name                = module.names["1"].virtual_network.name_unique

  subnets = {
    public = {
      address_prefix = "10.0.1.0/25"
      name           = "dbx_public"
      delegation = [{
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
      delegation = [{
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
  name                = module.names["1"].network_security_group.name_unique
  location            = local.databricks_location
  resource_group_name = azurerm_resource_group.dbx_example.name
}

resource "azurerm_databricks_workspace" "example" {
  name                = module.names["1"].databricks_workspace.name_unique
  location            = local.databricks_location
  resource_group_name = azurerm_resource_group.dbx_example.name
  sku                 = "premium"

  custom_parameters {
    virtual_network_id                                   = module.dbx_vnet.resource_id
    public_subnet_name                                   = module.dbx_vnet.subnets["public"].name
    private_subnet_name                                  = module.dbx_vnet.subnets["private"].name
    public_subnet_network_security_group_association_id  = module.dbx_vnet.subnets["public"].resource_id
    private_subnet_network_security_group_association_id = module.dbx_vnet.subnets["private"].resource_id
  }
}