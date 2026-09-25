# ---------------------------------------------------------------------------------------------------------------------
# Lean replacement for Azure/naming/azurerm 0.4.3, internal to this module.
#
# Azure/naming renders ~300 resource types on every call, and planning its ~300 outputs costs ~30 ms each. With one call
# per private endpoint that dominated callers' plan time. This module renders only the types used here, with the same
# formula, so every name is byte-identical.
#
# The random part MUST stay exactly as Azure/naming created it: same two resources, same arguments, same addresses
# (module call names are unchanged in the parent). Every deployed name embeds these values, and none of the named Azure
# resources can be renamed; a different random means a replacement. tests/unit-tests-naming.tftest.hcl checks parity.
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "main" {
  length  = 60
  numeric = true
  special = false
  upper   = false
}

resource "random_string" "first_letter" {
  length  = 1
  numeric = false
  special = false
  upper   = false
}

locals {
  # first_letter guarantees the unique part starts with a letter
  random        = substr(join("", [random_string.first_letter.result, random_string.main.result]), 0, 4)
  suffix_unique = join("-", concat(var.suffix, [local.random]))

  # slug and maximum length per type, as in Azure/naming 0.4.3
  types = {
    nat_gateway            = { slug = "ng", max_length = 80 }
    network_security_group = { slug = "nsg", max_length = 80 }
    private_endpoint       = { slug = "pe", max_length = 80 }
    public_ip              = { slug = "pip", max_length = 80 }
    resource_group         = { slug = "rg", max_length = 90 }
    subnet                 = { slug = "snet", max_length = 80 }
    virtual_network        = { slug = "vnet", max_length = 64 }
  }

  # Azure/naming: substr(join("-", compact([prefix, slug, suffix..., random])), 0, max) with an empty prefix. Only
  # name_unique is rendered: the parent module never reads Azure/naming's `name` (the variant without the random part).
  names = {
    for type, def in local.types : type => {
      name_unique = substr(join("-", compact([def.slug, local.suffix_unique])), 0, def.max_length)
    }
  }
}
