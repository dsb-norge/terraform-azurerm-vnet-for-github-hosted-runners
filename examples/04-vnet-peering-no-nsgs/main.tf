# tflint-ignore-file: azurerm_resource_tag
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
  version = "0.4.2"

  for_each = toset(["hub", "other"])

  suffix = ["example", each.value]
}

# will be reused by both VNets
resource "azurerm_resource_group" "example" {
  location = "norwayeast" # same as default location for the module
  name     = module.names["hub"].resource_group.name_unique
}

resource "azurerm_virtual_network" "hub" {
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  name                = module.names["hub"].virtual_network.name_unique
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "hub_default" {
  address_prefixes     = ["10.1.0.0/24"]
  name                 = module.names["hub"].subnet.name_unique
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.hub.name
}

resource "azurerm_virtual_network" "other" {
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.example.location
  name                = module.names["other"].virtual_network.name_unique
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "other_default" {
  address_prefixes     = ["10.2.0.0/24"]
  name                 = module.names["other"].subnet.name_unique
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.other.name
}

# GitHub runner VNet with the module's built-in NSGs disabled
# setup peering to the the two VNets created above
module "gh_vnet" {
  source = "../../"

  # required inputs
  github_database_id = "123456789"
  network_specs = {
    address_space = "10.3.0.0/16"
    tags = {
      ExapmleIPAMTag = "IPAM-reservation-ID"
    }
  }

  # disable the module's built-in NSGs
  disable_builtin_nsg_for_runner_subnet           = true
  disable_builtin_nsg_for_private_endpoint_subnet = true

  # do not provide outbound internet access through a NAT gateway
  # note: in a real-world scenario, would require the hub VNet to allow internet access
  disable_nat_gateway = true

  network_peering_configuration = {

    # minimal peering configuration to allow runners to use hub vnet as a gateway network to the internet
    hub = {
      remote_virtual_network_resource_id = azurerm_virtual_network.hub.id
      create_reverse_peering             = true # peering will be created in both directions
      allow_gateway_transit              = true # access to the internet through the remote VNet
    }

    # configuration that allows resources in 'other' VNet to access the runner VNet
    other = {
      remote_virtual_network_resource_id = azurerm_virtual_network.other.id
      create_reverse_peering             = true # peering will be created in both directions
      allow_forwarded_traffic            = true # allow traffic to flow from the remote VNet to the runner VNet
  } }
}
