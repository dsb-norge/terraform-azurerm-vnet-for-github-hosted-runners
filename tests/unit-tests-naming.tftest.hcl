# Parity between modules/naming and Azure/naming/azurerm 0.4.3, the module it replaces.
#
# Both modules get the same random_string results, and every name the parent module uses (`name_unique`) must come
# out identical.
# Deployed names embed these values, so any difference would replace the named Azure resources in callers.
#
# Only hashicorp/random is involved, and its results are overridden during plan: no Azure access is needed.

# Every run overrides random_string.main with the same fixed 60-character result and random_string.first_letter
# with "i", so the random part is "ik61". (Test-file variables are not visible inside override_resource, hence the
# repeated literals.)

# ----------------------------------------------------------------------------------------------------------------------
# typical suffix, as the parent module passes it
# ----------------------------------------------------------------------------------------------------------------------

run "legacy_typical" {
  command = plan

  module {
    source  = "Azure/naming/azurerm"
    version = "0.4.3"
  }

  variables {
    suffix = ["gh-iap-cm", "runners"]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }
}

run "lean_typical" {
  command = plan

  module {
    source = "./modules/naming"
  }

  variables {
    suffix = ["gh-iap-cm", "runners"]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }

  # the overrides took effect (both modules would otherwise agree on unknown values)
  assert {
    condition     = output.resource_group.name_unique == "rg-gh-iap-cm-runners-ik61"
    error_message = "Unexpected resource group name: ${output.resource_group.name_unique}"
  }

  assert {
    condition = alltrue([
      output.nat_gateway.name_unique == run.legacy_typical.nat_gateway.name_unique,
      output.network_security_group.name_unique == run.legacy_typical.network_security_group.name_unique,
      output.private_endpoint.name_unique == run.legacy_typical.private_endpoint.name_unique,
      output.public_ip.name_unique == run.legacy_typical.public_ip.name_unique,
      output.resource_group.name_unique == run.legacy_typical.resource_group.name_unique,
      output.subnet.name_unique == run.legacy_typical.subnet.name_unique,
      output.virtual_network.name_unique == run.legacy_typical.virtual_network.name_unique,
    ])
    error_message = "modules/naming differs from Azure/naming 0.4.3 for a typical suffix."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# long suffix: every name exceeds its maximum length (64 for vnet, 80, 90 for resource group) and is truncated
# ----------------------------------------------------------------------------------------------------------------------

run "legacy_long" {
  command = plan

  module {
    source  = "Azure/naming/azurerm"
    version = "0.4.3"
  }

  variables {
    suffix = ["a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-purpose-1234", "runners"]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }
}

run "lean_long" {
  command = plan

  module {
    source = "./modules/naming"
  }

  variables {
    suffix = ["a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-purpose-1234", "runners"]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }

  assert {
    condition     = length(output.virtual_network.name_unique) == 64 && length(output.resource_group.name_unique) == 90
    error_message = "The long-suffix case no longer exercises truncation."
  }

  assert {
    condition = alltrue([
      output.nat_gateway.name_unique == run.legacy_long.nat_gateway.name_unique,
      output.network_security_group.name_unique == run.legacy_long.network_security_group.name_unique,
      output.private_endpoint.name_unique == run.legacy_long.private_endpoint.name_unique,
      output.public_ip.name_unique == run.legacy_long.public_ip.name_unique,
      output.resource_group.name_unique == run.legacy_long.resource_group.name_unique,
      output.subnet.name_unique == run.legacy_long.subnet.name_unique,
      output.virtual_network.name_unique == run.legacy_long.virtual_network.name_unique,
    ])
    error_message = "modules/naming truncates differently from Azure/naming 0.4.3."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# empty suffix element: Azure/naming joins suffix elements without dropping empty ones
# ----------------------------------------------------------------------------------------------------------------------

run "legacy_empty_element" {
  command = plan

  module {
    source  = "Azure/naming/azurerm"
    version = "0.4.3"
  }

  variables {
    suffix = ["gh-iap-cm", ""]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }
}

run "lean_empty_element" {
  command = plan

  module {
    source = "./modules/naming"
  }

  variables {
    suffix = ["gh-iap-cm", ""]
  }

  override_resource {
    target          = random_string.main
    override_during = plan
    values = {
      result = "k61qzp0w9e8r7t6y5u4i3o2p1asdfghjklzxcvbnmqwertyuiop098765432"
    }
  }

  override_resource {
    target          = random_string.first_letter
    override_during = plan
    values = {
      result = "i"
    }
  }

  assert {
    condition = alltrue([
      output.resource_group.name_unique == run.legacy_empty_element.resource_group.name_unique,
      output.private_endpoint.name_unique == run.legacy_empty_element.private_endpoint.name_unique,
    ])
    error_message = "modules/naming handles an empty suffix element differently from Azure/naming 0.4.3."
  }
}
