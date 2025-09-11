provider "azurerm" {
  features {}
}

provider "azapi" {}

mock_provider "azurerm" {
  alias = "azurerm_mock"
}

mock_provider "azapi" {
  alias = "azapi_mock"
}

# Basic module validation with default values
run "verify_module_with_defaults" {
  command = plan
}

run "verify_github_database_id_validation" {
  command = plan

  variables {
    github_database_id = ""
  }

  expect_failures = [
    var.github_database_id,
  ]
}

run "verify_network_specs_address_space_format" {
  command = plan

  variables {
    network_specs = {
      address_space = "invalid-cidr"
    }
  }

  expect_failures = [
    var.network_specs,
  ]
}

run "verify_network_specs_allowed_without_tags" {
  command = plan

  variables {
    network_specs = {
      address_space = "10.0.0.0/25"
    }
  }
}

run "verify_system_name_validation" {
  command = plan

  variables {
    system_name = ""
  }

  expect_failures = [
    var.system_name,
  ]
}

run "verify_system_short_name_validation" {
  command = plan

  variables {
    system_short_name = ""
  }

  expect_failures = [
    var.system_short_name,
  ]
}

# Test tags validation
run "verify_tags_validation_empty_key" {
  command = plan

  variables {
    tags = { "" = "value" }
  }

  expect_failures = [
    var.tags,
  ]
}

run "verify_tags_validation_empty_value" {
  command = plan

  variables {
    tags = { "key" = "" }
  }

  expect_failures = [
    var.tags,
  ]
}

run "verify_tags_validation_null_value" {
  command = plan

  variables {
    tags = { "key" = null }
  }

  expect_failures = [
    var.tags,
  ]
}

run "verify_tags_value_length_too_long" {
  command = plan

  variables {
    tags = { "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890" }
  }

  expect_failures = [
    var.tags,
  ]
}

run "verify_storage_pe_tags_value_too_long" {
  command = plan

  variables {
    storage_account_private_endpoints = {
      "test-sa" = {
        resource_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Storage/storageAccounts/test-sa"
        create_blob_pe = true
        tags = {
          "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
        }
      }
    }
  }

  expect_failures = [
    var.storage_account_private_endpoints,
  ]
}

run "verify_key_vault_pe_tags_value_too_long" {
  command = plan

  variables {
    key_vault_private_endpoints = {
      "test-kv" = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.KeyVault/vaults/test-kv"
        tags = {
          "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
        }
      }
    }
  }

  expect_failures = [
    var.key_vault_private_endpoints,
  ]

}

run "verify_databricks_private_endpoints_tags_value_too_long" {
  command = plan

  variables {
    databricks_private_endpoints = {
      "test-dbx" = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Databricks/workspaces/test-dbx"
        tags = {
          "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
        }
      }
    }
  }

  expect_failures = [
    var.databricks_private_endpoints,
  ]
}

run "verify_sql_server_private_endpoints_tags_value_too_long" {
  command = plan

  variables {
    sql_server_private_endpoints = {
      "test-sql" = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Sql/servers/test-sql"
        tags = {
          "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
        }
      }
    }
  }

  expect_failures = [
    var.sql_server_private_endpoints,
  ]
}

run "verify_network_specs_tags_value_too_long" {
  command = plan

  variables {
    network_specs = {
      address_space = "10.0.0.0/25"
      tags = {
        "key" = "This is a very long value that is intentionally made to exceed the maximum allowed length of 250 characters for the tags variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
      }
    }
  }

  expect_failures = [
    var.network_specs,
  ]
}

# Test resource_id validation for key_vault_private_endpoints
run "verify_key_vault_resource_id_validation" {
  command = plan

  variables {
    key_vault_private_endpoints = {
      "test-kv" = {
        resource_id = "invalid-resource-id"
      }
    }
  }

  expect_failures = [
    var.key_vault_private_endpoints,
  ]
}

# Test databricks private endpoints validation
run "verify_databricks_resource_id_validation" {
  command = plan

  variables {
    databricks_private_endpoints = {
      "test-dbx" = {
        resource_id = "invalid-resource-id"
      }
    }
  }

  expect_failures = [
    var.databricks_private_endpoints,
  ]
}

# Test sql server private endpoints validation
run "verify_sql_server_resource_id_validation" {
  command = plan

  variables {
    sql_server_private_endpoints = {
      "test-sql" = {
        resource_id = "invalid-resource-id"
      }
    }
  }

  expect_failures = [
    var.sql_server_private_endpoints,
  ]
}

# Test storage account private endpoints validation
run "verify_storage_account_resource_id_validation" {
  command = plan

  variables {
    storage_account_private_endpoints = {
      "test-sa" = {
        resource_id    = "invalid-resource-id"
        create_blob_pe = true
      }
    }
  }

  expect_failures = [
    var.storage_account_private_endpoints,
  ]
}

run "verify_storage_account_endpoints_required" {
  command = plan

  variables {
    storage_account_private_endpoints = {
      "test-sa" = {
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Storage/storageAccounts/test-sa"
        create_blob_pe  = false
        create_file_pe  = false
        create_queue_pe = false
        create_table_pe = false
        create_web_pe   = false
        create_dfs_pe   = false
      }
    }
  }

  expect_failures = [
    var.storage_account_private_endpoints,
  ]
}

# Test network peering configuration validation
run "verify_network_peering_validation" {
  command = plan

  variables {
    network_peering_configuration = {
      "test-peering" = {
        remote_virtual_network_resource_id = "invalid-resource-id"
      }
    }
  }

  expect_failures = [
    var.network_peering_configuration,
  ]
}

# Test NSG resource ID validation for runner subnet
run "verify_nsg_for_runner_subnet_validation" {
  command = plan

  variables {
    nsg_for_runner_subnet = {
      id = "invalid-resource-id"
    }
  }

  expect_failures = [
    var.nsg_for_runner_subnet,
  ]
}

# Test NSG resource ID validation for private endpoint subnet
run "verify_nsg_for_private_endpoint_subnet_validation" {
  command = plan

  variables {
    nsg_for_private_endpoint_subnet = {
      id = "invalid-resource-id"
    }
  }

  expect_failures = [
    var.nsg_for_private_endpoint_subnet,
  ]
}

# Test additional NSG rules for runner subnet merge behavior
run "verify_additional_runner_nsg_rules" {
  command = plan

  variables {
    additional_nsg_rules_for_runner_subnet = {
      "AllowCustomOutboundService" = {
        access                     = "Allow"
        description                = "Allow outbound to custom service"
        priority                   = 1300
        protocol                   = "Tcp"
        direction                  = "Outbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "10.10.10.10"
        destination_port_range     = "443"
      }
    }
  }
}

# Test additional NSG rules for private endpoint subnet merge behavior
run "verify_additional_pe_nsg_rules" {
  command = plan

  variables {
    additional_nsg_rules_for_private_endpoint_subnet = {
      "AllowCustomInboundFromRunner" = {
        access                     = "Allow"
        description                = "Allow inbound custom port from runners"
        priority                   = 1300
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefixes    = ["10.0.0.0/26"]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "8080"
      }
    }
  }
}

# Test validation uniqueness for additional runner NSG rules priorities
run "verify_additional_runner_nsg_rules_priority_uniqueness" {
  command = plan

  variables {
    additional_nsg_rules_for_runner_subnet = {
      "RuleA" = {
        access                     = "Allow"
        description                = "A"
        priority                   = 1500
        protocol                   = "Tcp"
        direction                  = "Outbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "10.1.1.1"
        destination_port_range     = "443"
      }
      "RuleB" = {
        access                     = "Allow"
        description                = "B"
        priority                   = 1500 # duplicate
        protocol                   = "Tcp"
        direction                  = "Outbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "10.1.1.2"
        destination_port_range     = "443"
      }
    }
  }

  expect_failures = [
    var.additional_nsg_rules_for_runner_subnet,
  ]
}

# Test validation uniqueness for additional private endpoint NSG rules priorities
run "verify_additional_pe_nsg_rules_priority_uniqueness" {
  command = plan

  variables {
    additional_nsg_rules_for_private_endpoint_subnet = {
      "RuleA" = {
        access                     = "Allow"
        description                = "A"
        priority                   = 1600
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
      "RuleB" = {
        access                     = "Allow"
        description                = "B"
        priority                   = 1600 # duplicate
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
    }
  }

  expect_failures = [
    var.additional_nsg_rules_for_private_endpoint_subnet,
  ]
}

# NSG additional rules priority collision tests (runner subnet)
# Negative test: collision with built-in runner rule priority (1000) without override name
run "verify_runner_additional_nsg_priority_collision_without_override" {
  command = plan

  variables {
    additional_nsg_rules_for_runner_subnet = {
      "CustomRunnerRule" = {
        access                     = "Allow"
        description                = "Custom rule colliding with built-in priority 1000"
        priority                   = 1000 # collides with AllowPrivateEndpointOutbound (built-in) by priority only
        protocol                   = "Tcp"
        direction                  = "Outbound"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "10.50.0.10"
        destination_port_range     = "443"
      }
    }
  }

  expect_failures = [
    var.additional_nsg_rules_for_runner_subnet,
  ]
}

# NSG additional rules priority collision tests (runner subnet)
# Positive test: overriding built-in runner rule name allows using a colliding priority (or any priority)
run "verify_runner_additional_nsg_priority_override_allowed" {
  command = plan

  variables {
    additional_nsg_rules_for_runner_subnet = {
      # Override existing built-in rule "AllowPrivateEndpointOutbound" with new attributes & different priority
      "AllowPrivateEndpointOutbound" = {
        access                       = "Allow"
        description                  = "Override built-in rule with different priority"
        priority                     = 1015 # different from built-in 1000, but collision check skipped due to name override
        protocol                     = "Tcp"
        direction                    = "Outbound"
        source_address_prefix        = "*"
        source_port_range            = "*"
        destination_address_prefixes = ["10.60.0.0/26"]
        destination_port_range       = "443"
      }
    }
  }
}

# NSG additional rules priority collision tests (private endpoint subnet)
# Negative test: collision with built-in private endpoint rule priority (1000) without override
run "verify_pe_additional_nsg_priority_collision_without_override" {
  command = plan

  variables {
    additional_nsg_rules_for_private_endpoint_subnet = {
      "CustomPERule" = {
        access                     = "Allow"
        description                = "Custom PE rule colliding with built-in priority 1000"
        priority                   = 1000 # collides with AllowRunnerInbound
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefixes    = ["10.70.0.0/26"]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "8080"
      }
    }
  }

  expect_failures = [
    var.additional_nsg_rules_for_private_endpoint_subnet,
  ]
}

# NSG additional rules priority collision tests (private endpoint subnet)
# Positive test: overriding built-in private endpoint rule name allows any priority
run "verify_pe_additional_nsg_priority_override_allowed" {
  command = plan

  variables {
    additional_nsg_rules_for_private_endpoint_subnet = {
      # Override existing built-in rule name "AllowRunnerInbound"
      "AllowRunnerInbound" = {
        access                     = "Allow"
        description                = "Override built-in PE rule with new priority"
        priority                   = 1012 # different from built-in 1000
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefixes    = ["10.80.0.0/26"]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "8443"
      }
    }
  }
}

# Note:
#   since we are using avm modules we are not able to test using mock providers.
#   tests related to validating feature flags and outputs are not included here.
#
#   test coverage ensured by integration test tests/integration-test-01-basic.tftest.hcl
#
