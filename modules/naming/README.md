# `modules/naming` — internal naming for this module

Not intended for use outside this module.

This module replaces `Azure/naming/azurerm` 0.4.3 for the resource types the parent
module names: resource group, virtual network, subnet, network security group, NAT
gateway, public IP and private endpoint. It renders them with the same formula, so every
name is byte-identical, and it uses the same two `random_string` resources at the same
addresses. Only `name_unique` is rendered: the parent module never reads `name`.

`Azure/naming` renders ~300 resource types on every call, and planning its ~300 outputs
costs roughly 30 ms each. The parent module calls it once per private endpoint, so callers
with many endpoints spent minutes of every plan on it. This module computes 7 types.

## Rules

- **Do not change the `random_string` resources:** not their arguments, and not their
  names. Every deployed name embeds their values, and none of the named Azure resources
  can be renamed, so a change replaces them.
- **Do not change the formula or the maximum lengths** in `main.tf`.
- **Adding a type:** copy its slug and maximum length from `Azure/naming` 0.4.3 so names
  stay compatible, and add it to the parity test.

`tests/unit-tests-naming.tftest.hcl` in the parent module compares every output with
`Azure/naming` 0.4.3 for the same random values.
