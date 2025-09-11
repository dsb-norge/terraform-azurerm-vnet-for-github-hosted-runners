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

  # Example: Allow SSH access to runner subnet
  additional_nsg_rules_for_runner_subnet = {
    "AllowInboundSshFromTrustedNetwork" = {
      access                     = "Allow"
      description                = "Allow inbound SSH from trusted network"
      priority                   = 200
      protocol                   = "Tcp"
      direction                  = "Inbound"
      source_address_prefix      = "10.0.0.0/16" # Example trusted network
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "22"
    }
  }

  # Example: Allow HTTPS access to private endpoint subnet
  additional_nsg_rules_for_private_endpoint_subnet = {
    "AllowHttpsToSpecificIPRange" = {
      access      = "Allow"
      description = "Allow inbound HTTPS to specific IP range"
      priority    = 2000
      protocol    = "Tcp"
      direction   = "Inbound"
      source_address_prefixes = [
        # Example trusted networks
        "10.1.0.0/16",
        "10.2.0.0/16",
      ]
      source_port_range          = "*"
      destination_address_prefix = "10.0.0.0/24" # The entire VNet
      destination_port_range     = "443"
    }
  }
}
