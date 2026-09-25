# Migration from Azure/naming/azurerm 0.4.3 to modules/naming for a single naming call, without Azure access.
#
# Run 1 applies Azure/naming, creating its two random_string resources. Run 2 applies modules/naming against the same
# state (shared state_key). The resources, their arguments and their addresses are identical, so Terraform keeps both
# random_strings and every name stays the same. A replaced random_string would get a new result and change the names.
# tests/integration-test-07-migration-from-2.5.0.tftest.hcl covers the same for the whole module, with real resources.

run "create_with_azure_naming" {
  command   = apply
  state_key = "naming_migration"

  module {
    source  = "Azure/naming/azurerm"
    version = "0.4.3"
  }

  variables {
    suffix = ["gh-iap-cm", "keyvault"]
  }
}

run "apply_modules_naming_on_that_state" {
  command   = apply
  state_key = "naming_migration"

  module {
    source = "./modules/naming"
  }

  variables {
    suffix = ["gh-iap-cm", "keyvault"]
  }

  assert {
    condition = alltrue([
      output.nat_gateway.name_unique == run.create_with_azure_naming.nat_gateway.name_unique,
      output.network_security_group.name_unique == run.create_with_azure_naming.network_security_group.name_unique,
      output.private_endpoint.name_unique == run.create_with_azure_naming.private_endpoint.name_unique,
      output.public_ip.name_unique == run.create_with_azure_naming.public_ip.name_unique,
      output.resource_group.name_unique == run.create_with_azure_naming.resource_group.name_unique,
      output.subnet.name_unique == run.create_with_azure_naming.subnet.name_unique,
      output.virtual_network.name_unique == run.create_with_azure_naming.virtual_network.name_unique,
    ])
    error_message = "A name changed when modules/naming took over the state Azure/naming created."
  }
}
