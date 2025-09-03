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

run "varify_network_specs_allowed_without_tags" {
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

run "verify_storage_pe_description_tag_too_long" {
  command = plan

  variables {
    storage_pe_description_tag = "This is a very long description that is intentionally made to exceed the maximum allowed length of 250 characters for the storage_pe_description_tag variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
  }

  expect_failures = [
    var.storage_pe_description_tag,
  ]
}

run "verify_key_vault_pe_description_tag_too_long" {
  command = plan

  variables {
    key_vault_pe_description_tag = "This is a very long description that is intentionally made to exceed the maximum allowed length of 250 characters for the key_vault_pe_description_tag variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
  }

  expect_failures = [
    var.key_vault_pe_description_tag,
  ]
}

run "verify_dbx_pe_description_tag_too_long" {
  command = plan

  variables {
    dbx_pe_description_tag = "This is a very long description that is intentionally made to exceed the maximum allowed length of 250 characters for the dbx_pe_description_tag variable. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ExtraTextToReach260Chars1234567890"
  }

  expect_failures = [
    var.dbx_pe_description_tag,
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

# Note:
#   since we are using avm modules we are not able to test using mock providers.
#   tests related to validating feature flags and outputs are not included here.
#
#   test coverage ensured by integration test tests/integration-test-01-basic.tftest.hcl
#
