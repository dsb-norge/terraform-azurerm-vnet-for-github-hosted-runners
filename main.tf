locals {
  # feature toggles
  should_create_nsg_for_runner_subnet = var.nsg_for_runner_subnet == null && !var.disable_builtin_nsg_for_runner_subnet
  should_create_nsg_for_pe_subnet     = var.nsg_for_private_endpoint_subnet == null && !var.disable_builtin_nsg_for_private_endpoint_subnet
  should_create_nat_gateway           = !var.disable_nat_gateway

  # network address space
  runner_subnet_address_prefixes = [cidrsubnet(var.network_specs.address_space, 1, 0)]
  pe_subnet_address_prefixes     = [cidrsubnet(var.network_specs.address_space, 1, 1)]

}

# create name most resources
module "runner_name" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = [var.system_short_name, "runners"]
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.runner_name.resource_group.name_unique
  tags = merge(var.tags, {
    Description = "Resource group for virtual network designed to host GitHub hosted Actions runners in the '${var.system_name}' infrastructure"
  })
}

# create names for subnets and network security groups
module "subnet_names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = toset(["runner", "pe"])

  suffix = [var.system_short_name, each.value]
}

locals {
  # support disabling NSGs
  nsgs_to_create = merge(
    local.should_create_nsg_for_runner_subnet ? {
      runner = {
        name      = module.subnet_names["runner"].network_security_group.name_unique
        nsg_rules = local.nsg_rules_runner_subnet
    } } : {},
    local.should_create_nsg_for_pe_subnet ? {
      pe = {
        name      = module.subnet_names["pe"].network_security_group.name_unique
        nsg_rules = local.nsg_rules_private_endpoint_subnet
    } } : {},
  )
}

# conditional NSG creation
resource "azurerm_network_security_group" "this" {
  for_each = local.nsgs_to_create

  location            = var.location
  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(var.tags, {
    Description = "Network security group for '${each.key}' subnet in '${var.system_name}' infrastructure"
  })

  dynamic "security_rule" {
    for_each = each.value.nsg_rules

    content {
      access                       = security_rule.value.access
      description                  = security_rule.value.description
      destination_address_prefix   = security_rule.value.destination_address_prefix
      destination_address_prefixes = security_rule.value.destination_address_prefixes
      destination_port_range       = security_rule.value.destination_port_range
      destination_port_ranges      = security_rule.value.destination_port_ranges
      direction                    = security_rule.value.direction
      name                         = security_rule.key
      priority                     = security_rule.value.priority
      protocol                     = security_rule.value.protocol
      source_address_prefix        = security_rule.value.source_address_prefix
      source_address_prefixes      = security_rule.value.source_address_prefixes
      source_port_range            = security_rule.value.source_port_range
    }
  }
}

# NAT Gateway with Public IP to enable outbound internet access for GitHub actions runners
resource "azurerm_nat_gateway" "this" {
  count = local.should_create_nat_gateway ? 1 : 0

  location            = var.location
  name                = module.runner_name.nat_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(var.tags, {
    Description = "NAT gateway for for outbound traffic to the Internet from Virtual network designed to host GitHub hosted Actions runners in the '${var.system_name}' infrastructure"
  })
}

resource "azurerm_public_ip" "this" {
  count = local.should_create_nat_gateway ? 1 : 0

  allocation_method   = "Static"
  location            = var.location
  name                = module.runner_name.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  tags = merge(var.tags, {
    Description = "Public IP for outbound traffic to the Internet from Virtual network designed to host GitHub hosted Actions runners in the '${var.system_name}' infrastructure"
  })
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = local.should_create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.this[0].id
}

# create the GitHub hosted runners virtual network
module "gh_runner_vnet" {

  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = module.runner_name.virtual_network.name_unique
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = tolist(compact(concat([var.network_specs.address_space], var.network_specs.additional_pe_subnet)))

  tags = merge(var.tags, var.network_specs.tags, {
    Description = "Virtual network designed to host GitHub hosted Actions runners in the '${var.system_name}' infrastructure"
  })

  subnets = {
    gh_runners = {
      name             = module.subnet_names["runner"].subnet.name_unique
      address_prefixes = local.runner_subnet_address_prefixes

      # support disabling creation of NAT Gateway
      nat_gateway = local.should_create_nat_gateway ? { id = azurerm_nat_gateway.this[0].id } : null

      #this delegation is required so GitHub hosted runners can deploy NICs in the subnet
      delegation = [{
        name = "GitHub.Network/networkSettings"
        service_delegation = {
          name = "GitHub.Network/networkSettings"
        }
      }]

      # support disabling NSGs and bringing your own
      network_security_group = (
        local.should_create_nsg_for_runner_subnet
        # we created a nsg, use it
        ? { id = azurerm_network_security_group.this["runner"].id }
        # either it was supplied or this is null
        : var.nsg_for_runner_subnet
    ) }

    pe_subnet = {
      name             = module.subnet_names["pe"].subnet.name_unique
      address_prefixes = tolist(compact(concat(local.pe_subnet_address_prefixes, var.network_specs.additional_pe_subnet)))

      # support disabling NSGs and bringing your own
      network_security_group = (
        local.should_create_nsg_for_pe_subnet
        # we created a nsg, use it
        ? { id = azurerm_network_security_group.this["pe"].id }
        # either it was supplied or this is null
        : var.nsg_for_private_endpoint_subnet
    ) }
  }

  peerings = {
    for key, value in var.network_peering_configuration :
    key => {
      name                                 = "${module.runner_name.subnet.name_unique}-gh-to-${provider::azurerm::parse_resource_id(value.remote_virtual_network_resource_id).resource_name}"
      remote_virtual_network_resource_id   = value.remote_virtual_network_resource_id
      allow_virtual_network_access         = value.allow_virtual_network_access
      allow_forwarded_traffic              = value.allow_forwarded_traffic
      allow_gateway_transit                = value.allow_gateway_transit
      use_remote_gateways                  = value.use_remote_gateways
      create_reverse_peering               = value.create_reverse_peering
      reverse_name                         = value.create_reverse_peering ? provider::azurerm::parse_resource_id(value.remote_virtual_network_resource_id).resource_name : null
      reverse_allow_virtual_network_access = value.reverse_allow_virtual_network_access
      reverse_allow_forwarded_traffic      = value.reverse_allow_forwarded_traffic
      reverse_allow_gateway_transit        = value.reverse_allow_gateway_transit
      reverse_use_remote_gateways          = value.reverse_use_remote_gateways
    }
  }
}

# Resource below create network settings resource that is associate subnet with GitHub  database id.
#
# See documentation for enterprise:
#   https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners-in-your-enterprise
#
# See documentation for organization:
#   https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization
resource "azapi_resource" "network_settings" {
  type = "GitHub.Network/networkSettings@2024-04-02"

  name      = "GitHubNetwork-${module.gh_runner_vnet.name}"
  parent_id = azurerm_resource_group.this.id
  location  = var.location

  body = {
    properties = {
      # businessId	Specifies the GitHub business (enterprise/organization) ID associated to the Azure subscription (string)
      subnetId = module.gh_runner_vnet.subnets.gh_runners.resource_id
      # subnetId	Specifies a subnet ID for vnet-injection (string)
      businessId = var.github_database_id
    }
  }

  # these are the interesting ones, used in module outputs
  response_export_values = ["tags.GitHubId", "name"]

  # Silence false positive config drift in plan output
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
