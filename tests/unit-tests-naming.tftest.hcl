# Parity between modules/naming and Azure/naming/azurerm 0.4.3, the module it replaced.
#
# Every name the parent module uses (`name_unique`) must come out exactly as Azure/naming 0.4.3 rendered it from the
# same random_string results. Deployed names embed these values, so any difference would replace the named Azure
# resources in callers.
#
# The expected names below were rendered by Azure/naming/azurerm 0.4.3 itself, from the same overridden random values
# and suffixes. They are the reference: never edit them to make a test pass.
#
# Only hashicorp/random is involved, and its results are overridden during plan: no Azure access is needed.

# Every run overrides random_string.main with the same fixed 60-character result and random_string.first_letter
# with "i", so the random part is "ik61". (Test-file variables are not visible inside override_resource, hence the
# repeated literals.)

# ----------------------------------------------------------------------------------------------------------------------
# typical suffix, as the parent module passes it
# ----------------------------------------------------------------------------------------------------------------------

run "typical" {
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

  assert {
    condition = alltrue([
      output.nat_gateway.name_unique == "ng-gh-iap-cm-runners-ik61",
      output.network_security_group.name_unique == "nsg-gh-iap-cm-runners-ik61",
      output.private_endpoint.name_unique == "pe-gh-iap-cm-runners-ik61",
      output.public_ip.name_unique == "pip-gh-iap-cm-runners-ik61",
      output.resource_group.name_unique == "rg-gh-iap-cm-runners-ik61",
      output.subnet.name_unique == "snet-gh-iap-cm-runners-ik61",
      output.virtual_network.name_unique == "vnet-gh-iap-cm-runners-ik61",
    ])
    error_message = "modules/naming differs from Azure/naming 0.4.3 for a typical suffix."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# long suffix: every name exceeds its maximum length (64 for vnet, 80, 90 for resource group) and is truncated
# ----------------------------------------------------------------------------------------------------------------------

run "long" {
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
    condition = alltrue([
      output.nat_gateway.name_unique == "ng-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-p",
      output.network_security_group.name_unique == "nsg-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-",
      output.private_endpoint.name_unique == "pe-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-p",
      output.public_ip.name_unique == "pip-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-",
      output.resource_group.name_unique == "rg-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on-purpose-123",
      output.subnet.name_unique == "snet-a-very-long-system-short-name-that-exceeds-every-azure-name-length-limit-on",
      output.virtual_network.name_unique == "vnet-a-very-long-system-short-name-that-exceeds-every-azure-name",
    ])
    error_message = "modules/naming truncates differently from Azure/naming 0.4.3."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# empty suffix element: Azure/naming joins suffix elements without dropping empty ones
# ----------------------------------------------------------------------------------------------------------------------

run "empty_element" {
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
      output.nat_gateway.name_unique == "ng-gh-iap-cm--ik61",
      output.network_security_group.name_unique == "nsg-gh-iap-cm--ik61",
      output.private_endpoint.name_unique == "pe-gh-iap-cm--ik61",
      output.public_ip.name_unique == "pip-gh-iap-cm--ik61",
      output.resource_group.name_unique == "rg-gh-iap-cm--ik61",
      output.subnet.name_unique == "snet-gh-iap-cm--ik61",
      output.virtual_network.name_unique == "vnet-gh-iap-cm--ik61",
    ])
    error_message = "modules/naming handles an empty suffix element differently from Azure/naming 0.4.3."
  }
}
