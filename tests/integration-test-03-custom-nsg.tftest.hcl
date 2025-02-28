# attempt to apply example

provider "azurerm" {
  features {}
}

provider "azapi" {}

run "validate_custom_nsg_example" {
  command = apply

  module {
    source = "./examples/03-custom-nsg"
  }

  # test coverage of output values ensured by tests/integration-test-01-basic.tftest.hcl
}

# TODO: Verify custom NSGs are correctly configured, need separate module for this
