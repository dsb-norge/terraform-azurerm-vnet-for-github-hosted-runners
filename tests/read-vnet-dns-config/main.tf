# tflint-ignore-file: terraform_standard_module_structure, terraform_variable_separate, terraform_output_separate, azurerm_resource_tag

# Read back VNet DNS configuration and NSG rules from deployed resources
# using azurerm data sources, following the pattern from terraform-azurerm-mgmt-resource-lock

variable "nsg_name" {
  description = "The name of the runner subnet NSG to read security rules from"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group name containing the VNet and NSG"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network to read DNS configuration from"
  type        = string
}

# read VNet resource to get DNS server configuration
data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

# read NSG resource to get security rules
data "azurerm_network_security_group" "this" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
}

locals {
  # extract security rules from NSG and build a map keyed by rule name
  nsg_security_rules = {
    for rule in data.azurerm_network_security_group.this.security_rule :
    rule.name => {
      name                         = rule.name
      priority                     = rule.priority
      protocol                     = rule.protocol
      access                       = rule.access
      direction                    = rule.direction
      source_address_prefix        = rule.source_address_prefix
      source_address_prefixes      = rule.source_address_prefixes
      destination_address_prefix   = rule.destination_address_prefix
      destination_address_prefixes = rule.destination_address_prefixes
      destination_port_range       = rule.destination_port_range
      destination_port_ranges      = rule.destination_port_ranges
    }
  }
}

output "dns_servers" {
  description = "List of DNS servers configured on the virtual network"
  value       = data.azurerm_virtual_network.this.dns_servers
}

output "nsg_security_rules" {
  description = <<-DESC
    Map of NSG security rules on the runner subnet NSG, keyed by rule name.

    nsg_security_rules = map(object({
      name                         = string
      priority                     = number
      protocol                     = string
      access                       = string
      direction                    = string
      source_address_prefix        = string
      source_address_prefixes      = list(string)
      destination_address_prefix   = string
      destination_address_prefixes = list(string)
      destination_port_range       = string
      destination_port_ranges      = list(string)
    }))
    DESC
  value       = local.nsg_security_rules
}
