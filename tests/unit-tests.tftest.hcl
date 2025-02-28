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

run "verify_network_address_space_format" {
  command = plan

  variables {
    network_address_space = "invalid-cidr"
  }

  expect_failures = [
    var.network_address_space,
  ]
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
