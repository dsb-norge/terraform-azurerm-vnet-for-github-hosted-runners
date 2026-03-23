# apply example with custom DNS servers and BYO DNS zone, then read back and verify

provider "azurerm" {
  features {}
}

provider "azapi" {}

# apply the example
run "apply" {
  command = apply

  module {
    source = "./examples/06-dns-servers"
  }

  # verify outputs are populated
  assert {
    condition     = length(output.virtual_network_resource_id) > 0
    error_message = "The output virtual_network_resource_id is empty."
  }

  assert {
    condition     = length(output.runner_nsg_resource_id) > 0
    error_message = "The output runner_nsg_resource_id is empty."
  }

  # verify BYO blob DNS zone ID matches what the module reports
  assert {
    condition     = output.storage_private_dns_zone_ids["blob"] == output.byo_blob_dns_zone_id
    error_message = "Expected storage_private_dns_zone_ids['blob'] to match the BYO blob DNS zone ID"
  }
}

# read back the VNet and NSG from Azure to verify deployed configuration
run "verify" {
  command = apply

  variables {
    vnet_name           = run.apply.vnet_name
    nsg_name            = run.apply.runner_nsg_name
    resource_group_name = run.apply.resource_group_name
  }

  module {
    source = "./tests/read-vnet-dns-config"
  }

  # verify custom DNS server is configured on the VNet
  assert {
    condition     = contains(output.dns_servers, "10.0.0.4")
    error_message = "Expected VNet DNS servers to contain '10.0.0.4'"
  }

  assert {
    condition     = length(output.dns_servers) == 1
    error_message = "Expected exactly 1 DNS server configured on the VNet, got ${length(output.dns_servers)}"
  }

  # verify AllowDnsProxyOutbound NSG rule exists
  assert {
    condition     = can(output.nsg_security_rules["AllowDnsProxyOutbound"])
    error_message = "Expected 'AllowDnsProxyOutbound' NSG rule to exist on runner subnet"
  }

  # verify NSG rule has correct priority
  assert {
    condition     = output.nsg_security_rules["AllowDnsProxyOutbound"].priority == 1150
    error_message = "Expected 'AllowDnsProxyOutbound' rule priority to be 1150"
  }

  # verify NSG rule targets port 53
  assert {
    condition     = output.nsg_security_rules["AllowDnsProxyOutbound"].destination_port_range == "53"
    error_message = "Expected 'AllowDnsProxyOutbound' rule to target port 53"
  }

  # verify NSG rule direction is Outbound
  assert {
    condition     = output.nsg_security_rules["AllowDnsProxyOutbound"].direction == "Outbound"
    error_message = "Expected 'AllowDnsProxyOutbound' rule direction to be 'Outbound'"
  }

  # verify NSG rule targets the configured DNS server IP
  assert {
    condition     = contains(output.nsg_security_rules["AllowDnsProxyOutbound"].destination_address_prefixes, "10.0.0.4")
    error_message = "Expected 'AllowDnsProxyOutbound' rule destination to contain '10.0.0.4'"
  }

  # verify NSG rule access is Allow
  assert {
    condition     = output.nsg_security_rules["AllowDnsProxyOutbound"].access == "Allow"
    error_message = "Expected 'AllowDnsProxyOutbound' rule access to be 'Allow'"
  }
}
