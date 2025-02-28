# attempt to apply example

provider "azurerm" {
  features {}
}

provider "azapi" {}

run "validate_private_endpoints_example" {
  command = apply

  module {
    source = "./examples/02-private-endpoints"
  }

  # test coverage of output values ensured by tests/integration-test-01-basic.tftest.hcl
}

# TODO: Verify private endpoints are correctly configured, need separate module for this
