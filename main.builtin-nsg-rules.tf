# built-in NSGs bundled with this module
#
locals {
  ################################################
  # for the GitHub hosted runner subnet
  ################################################

  nsg_rules_runner_subnet = {
    ################
    # Outbound rules
    ################

    # Allow all outbound traffic from GitHub hosted runners to private endpoints subnet.
    "AllowPrivateEndpointOutbound" = {
      access                = "Allow"
      description           = "Allow all outbound traffic from GitHub hosted runners to private endpoints subnet"
      priority              = 1000
      protocol              = "*"
      direction             = "Outbound"
      source_address_prefix = "*"
      source_port_range     = "*"
      # destination_address_prefix   not specified
      destination_address_prefixes = local.pe_subnet_address_prefixes
      destination_port_range       = "*"
    }
    # Allow all outbound traffic from GitHub hosted runners to virtual networks in Azure.
    # This includes the private endpoint subnet and any peered virtual networks.
    "AllowVnetOutbound" = {
      access                     = "Allow"
      description                = "Allow all outbound traffic from GitHub hosted runners to virtual networks in Azure"
      priority                   = 1100
      protocol                   = "*"
      direction                  = "Outbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "*"
    }
    # Allow https outbound to Internet from runners.
    "AllowHttpsInternetOutbound" = {
      access                     = "Allow"
      description                = "Allows https outbound to Internet from GitHub hosted runners"
      priority                   = 1200
      protocol                   = "Tcp"
      direction                  = "Outbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "Internet"
      destination_port_range     = "443"
    }
    # Catch-all to block outbound traffic not allowed by other outbound rules. Effectively overriding Azure default rules.
    "DenyAllOutbound" = {
      access                     = "Deny"
      description                = "Deny all other outbound traffic from GitHub hosted runners to all destinations"
      priority                   = 4060 # max is 4096, add this rule at the bottom leaving room for other rules
      protocol                   = "*"
      direction                  = "Outbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }

    ################
    # Inbound rules
    ################
    # GitHub runners should not receive any inbound traffic.
    "DenyAllInbound" = {
      access                     = "Deny"
      description                = "Deny all inbound traffic to GitHub hosted runners from all sources"
      priority                   = 4060 # max is 4096, add this rule at the bottom leaving room for other rules
      protocol                   = "*"
      direction                  = "Inbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
  } }

  ################################################
  # for the private endpoint subnet
  ################################################
  nsg_rules_private_endpoint_subnet = {
    ################
    # Outbound rules
    ################

    # Private endpoints should not emit any outbound traffic.
    "DenyAllOutbound" = {
      access                     = "Deny"
      description                = "Deny all outbound traffic"
      priority                   = 4060 # max is 4096, add this rule at the bottom leaving room for other rules
      protocol                   = "*"
      direction                  = "Outbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_address_prefix = "*"
    }

    ################
    # Inbound rules
    ################

    # Allow all inbound traffic from GitHub hosted runners to the private endpoint subnet.
    "AllowRunnerInbound" = {
      access      = "Allow"
      description = "Allow all traffic from GitHub hosted runners to the private endpoint subnet"
      priority    = 1000
      protocol    = "*"
      direction   = "Inbound"
      # source_address_prefix      not specified
      source_address_prefixes    = local.runner_subnet_address_prefixes
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
    }
    # Catch-all to block inbound traffic not allowed by other inbound rules. Effectively overriding Azure default rules.
    "DenyAllInbound" = {
      access                     = "Deny"
      description                = "Deny all inbound traffic to the subnet from all sources"
      priority                   = 4060 # max is 4096, add this rule at the bottom leaving room for other rules
      protocol                   = "*"
      direction                  = "Inbound"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
  } }
}
