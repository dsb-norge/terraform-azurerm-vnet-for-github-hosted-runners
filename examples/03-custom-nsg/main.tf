# tflint-ignore-file: azurerm_resource_tag
#
provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

# unique names to avoid name collisions during integration testing
module "names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = ["example"]
}

# Create a resource group for the example
resource "azurerm_resource_group" "example" {
  location = "norwayeast" # same as default location for the module
  name     = module.names.resource_group.name_unique
}

# create a custom NSG for the runner subnet
resource "azurerm_network_security_group" "runner" {
  location            = azurerm_resource_group.example.location
  name                = module.names.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.example.name

  # Allow GitHub Actions runner traffic
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "AllowGitHubActions"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }

  # Example: Allow SSH access to runner subnet (for debugging)
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "AllowSSH"
    priority                   = 200
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16" # Example trusted network
    source_port_range          = "*"
  }

  # Block all other inbound traffic by default
  security_rule {
    access                     = "Deny"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    direction                  = "Inbound"
    name                       = "DenyAllInbound"
    priority                   = 4096
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

# Call the module with the custom NSG
module "gh_vnet" {
  source = "../../"

  # required inputs
  github_database_id = "123456789"
  network_specs = {
    address_space = "10.0.0.0/24"
    tags = {
      ExampleIPAMTag = "IPAM-reservation-ID"
    }
  }

  # the module comes with 2 built-in NSGs, one for the runner subnet and one for the private endpoint subnet
  # here we use the built-in one for the private endpoint subnet
  # and use a custom NSG for the runner subnet
  nsg_for_runner_subnet = { id = azurerm_network_security_group.runner.id }
}
