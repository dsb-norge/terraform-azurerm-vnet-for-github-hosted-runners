# Example of peering to other VNets and disabling the module's built-in NSGs

This example sets up two virtual networks with one subnet in each. The two VNets are peered to the Azure Virtual Network designed to host GitHub hosted Actions runners. Additionally, the example disables the creation of Network Security Groups built into the module.

Note: in a real world scenario, routing to the internet must be provided by the peered hub VNet.

Also note: you would probably also want to configure custom NSGs by using the inputs `nsg_for_runner_subnet` and `nsg_for_private_endpoint_subnet`.

<!-- BEGIN_TF_DOCS -->

```hcl
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
  name     = module.names["hub"].resource_group.name_unique
  location = "norwayeast" # same as default location for the module
}

resource "azurerm_virtual_network" "hub" {
  name                = module.names["hub"].virtual_network.name_unique
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "hub_default" {
  name                 = module.names["hub"].subnet.name_unique
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_virtual_network" "other" {
  name                = module.names["other"].virtual_network.name_unique
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "other_default" {
  name                 = module.names["other"].subnet.name_unique
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.other.name
  address_prefixes     = ["10.2.0.0/24"]
}

# GitHub runner VNet with the module's built-in NSGs disabled
# setup peering to the the two VNets created above
module "gh_vnet" {
  source = "../../"

  # required inputs
  github_database_id    = "123456789"
  network_address_space = "10.3.0.0/16"

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
```

## Outputs

The following outputs are exported:

### <a name="output_github_network_settings_id"></a> [github\_network\_settings\_id](#output\_github\_network\_settings\_id)

Description: The resource ID of the GitHub Network settings resource

### <a name="output_github_network_settings_name"></a> [github\_network\_settings\_name](#output\_github\_network\_settings\_name)

Description: Name of the Github Network settings resource

### <a name="output_outbound_ip_address"></a> [outbound\_ip\_address](#output\_outbound\_ip\_address)

Description: The outbound NAT public IP address used by runners to access the internet

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The resource ID of the resource group containing the resources for the Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners

### <a name="output_virtual_network_resource_id"></a> [virtual\_network\_resource\_id](#output\_virtual\_network\_resource\_id)

Description: The resource ID of the virtual network (VNet) designed to host GitHub hosted Actions runners
<!-- END_TF_DOCS -->