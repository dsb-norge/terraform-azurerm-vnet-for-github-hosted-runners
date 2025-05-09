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
  name     = module.names.resource_group.name_unique
  location = "norwayeast" # same as default location for the module
}

# create a custom NSG for the runner subnet
resource "azurerm_network_security_group" "runner" {
  name                = module.names.network_security_group.name_unique
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Allow GitHub Actions runner traffic
  security_rule {
    name                       = "AllowGitHubActions"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Example: Allow SSH access to runner subnet (for debugging)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/16" # Example trusted network
    destination_address_prefix = "*"
  }

  # Block all other inbound traffic by default
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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
