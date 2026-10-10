# ---------------------------------------------------------------------------------------------------------------------
# Frozen copy of the state-bearing part of Azure/naming/azurerm 0.4.3, for tests/unit-tests-naming-migration.tftest.hcl.
#
# Callers on 2.5.0 and older have these two random_string resources in their state, created by Azure/naming. The
# resources, their arguments and their addresses are copied from Azure/naming 0.4.3 as it ran there: `numeric` is the
# default of its `unique-include-numbers` (true), and the `random` output follows its formula with the defaults of
# `unique-seed` ("") and `unique-length` (4), none of which this module ever set.
#
# This is the reference modules/naming must take over. Never edit it to make a test pass.
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "main" {
  length  = 60
  special = false
  upper   = false
  numeric = true
}

resource "random_string" "first_letter" {
  length  = 1
  special = false
  upper   = false
  numeric = false
}
