# attempt to apply example

provider "azurerm" {
  features {}
}

provider "azapi" {}

run "validate_vnet_peering_example" {
  command = apply

  module {
    source = "./examples/04-vnet-peering-no-nsgs"
  }

  assert {
    condition     = can(output.outbound_ip_address)
    error_message = "Failed to access outbound_ip_address output from the module in the VNet peering example."
  }

  assert {
    condition     = output.outbound_ip_address == null
    error_message = "The output outbound_ip_address is expected to be null for when module is called with 'disable_nat_gateway = true'."
  }
}

# TODO: Verify VNet peering configuration is correctly applied, need separate module for this
# TODO: Verify NSGs are disabled, need separate module for this
