# Migration from Azure/naming/azurerm 0.4.3 to modules/naming for a single naming call, without Azure access.
#
# Run 1 applies tests/naming-migration/azure-naming-0.4.3, a frozen copy of the two random_string resources Azure/naming
# created in callers' state. Run 2 applies modules/naming against the same state (shared state_key). The resources,
# their arguments and their addresses are identical, so Terraform keeps both random_strings and every name ends in the
# random part Azure/naming created. A replaced random_string would get a new result and change the names.
# tests/integration-test-07-migration-from-2.5.0.tftest.hcl covers the same for the whole module, with real resources.

run "create_azure_naming_state" {
  command   = apply
  state_key = "naming_migration"

  module {
    source = "./tests/naming-migration/azure-naming-0.4.3"
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
      output.nat_gateway.name_unique == "ng-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.network_security_group.name_unique == "nsg-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.private_endpoint.name_unique == "pe-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.public_ip.name_unique == "pip-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.resource_group.name_unique == "rg-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.subnet.name_unique == "snet-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
      output.virtual_network.name_unique == "vnet-gh-iap-cm-keyvault-${run.create_azure_naming_state.random}",
    ])
    error_message = "A name changed when modules/naming took over the state Azure/naming created."
  }
}
