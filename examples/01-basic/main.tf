provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "gh_vnet" {
  source = "../../"

  github_database_id    = "123456789"
  network_address_space = "10.0.0.0/24"
}
