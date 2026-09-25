# Upgrading a caller from 2.5.0, the last release on Azure/naming/azurerm, must not replace any Azure resource.
#
# Run 1 deploys the caller in tests/migration/legacy/ with module 2.5.0 from the registry. Run 2 applies the identical
# caller in tests/migration/current/, which uses this checkout, against the same state (shared state_key). Every name
# embeds the random part Azure/naming created, and none of the named resources can be renamed. So a resource whose name
# changed would be replaced, and would get a new resource ID. Unchanged IDs, private endpoint names and NAT gateway
# public IP after run 2 show the upgrade replaced nothing.

provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

run "deploy_with_2_5_0" {
  command   = apply
  state_key = "migration_from_2_5_0"

  module {
    source = "./tests/migration/legacy"
  }

  assert {
    condition     = length(output.private_endpoint_names) == 1
    error_message = "Expected exactly one private endpoint in the 2.5.0 deployment, got: ${jsonencode(output.private_endpoint_names)}"
  }
}

run "apply_this_checkout_on_that_state" {
  command   = apply
  state_key = "migration_from_2_5_0"

  module {
    source = "./tests/migration/current"
  }

  assert {
    condition     = output.resource_group_id == run.deploy_with_2_5_0.resource_group_id
    error_message = "The resource group was replaced by the upgrade."
  }

  assert {
    condition     = output.virtual_network_resource_id == run.deploy_with_2_5_0.virtual_network_resource_id
    error_message = "The virtual network was replaced by the upgrade."
  }

  assert {
    condition = alltrue([
      output.runner_subnet_resource_id == run.deploy_with_2_5_0.runner_subnet_resource_id,
      output.private_endpoint_subnet_resource_id == run.deploy_with_2_5_0.private_endpoint_subnet_resource_id,
      output.runner_nsg_resource_id == run.deploy_with_2_5_0.runner_nsg_resource_id,
    ])
    error_message = "A subnet or network security group was replaced by the upgrade."
  }

  assert {
    condition     = output.outbound_ip_address == run.deploy_with_2_5_0.outbound_ip_address
    error_message = "The NAT gateway public IP was replaced by the upgrade."
  }

  assert {
    condition     = output.github_network_settings_id == run.deploy_with_2_5_0.github_network_settings_id
    error_message = "The GitHub network settings resource was replaced by the upgrade."
  }

  assert {
    condition     = output.private_endpoint_names == run.deploy_with_2_5_0.private_endpoint_names
    error_message = "The private endpoint was renamed by the upgrade: ${jsonencode(run.deploy_with_2_5_0.private_endpoint_names)} -> ${jsonencode(output.private_endpoint_names)}"
  }
}
