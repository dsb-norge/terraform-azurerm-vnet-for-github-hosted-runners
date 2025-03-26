# attempt to apply examples, verify outputs

provider "azurerm" {
  features {}
}

provider "azapi" {}

run "validate_basic_example" {
  command = apply

  module {
    source = "./examples/01-basic"
  }

  assert {
    condition     = can(output.resource_group_id)
    error_message = "Failed to access resource_group_id output from the module in the basic example."
  }

  assert {
    condition     = length(output.resource_group_id) > 0
    error_message = "The output resource_group_id is empty."
  }

  assert {
    condition     = strcontains(output.resource_group_id, "gh-hosted")
    error_message = "The output resource_group_id does not contain the the default system_short_name 'gh-hosted'."
  }

  assert {
    condition     = can(output.github_network_settings_id)
    error_message = "Failed to access github_network_settings_id output from the module in the basic example."
  }

  assert {
    condition     = length(output.github_network_settings_id) > 0
    error_message = "The output github_network_settings_id is empty."
  }

  assert {
    condition     = can(parseint(output.github_network_settings_id, 16))
    error_message = "The output github_network_settings_id is expected to be parseable as a hexadecimal number."
  }

  assert {
    condition     = can(output.github_network_settings_name)
    error_message = "Failed to access github_network_settings_name output from the module in the basic example."
  }

  assert {
    condition     = length(output.github_network_settings_name) > 0
    error_message = "The output github_network_settings_name is empty."
  }

  assert {
    condition     = strcontains(output.github_network_settings_name, "gh-hosted")
    error_message = "The output github_network_settings_name does not contain the the default system_short_name 'gh-hosted'."
  }

  assert {
    condition     = can(output.outbound_ip_address)
    error_message = "Failed to access outbound_ip_address output from the module in the basic example."
  }

  assert {
    condition     = can(cidrnetmask("${output.outbound_ip_address}/32"))
    error_message = "The output outbound_ip_address is not a valid CIDR netmask."
  }

  assert {
    condition     = can(output.virtual_network_resource_id)
    error_message = "Failed to access virtual_network_resource_id output from the module in the basic example."
  }

  assert {
    condition     = length(output.virtual_network_resource_id) > 0
    error_message = "The output virtual_network_resource_id is empty."
  }

  assert {
    condition     = strcontains(output.virtual_network_resource_id, "/virtualNetworks/")
    error_message = "The output virtual_network_resource_id does not contain the expected '/virtualNetworks/' pattern."
  }
}
