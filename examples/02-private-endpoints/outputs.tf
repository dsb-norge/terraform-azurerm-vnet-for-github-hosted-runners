# outputs are created to facilitate using this example for integration testing

output "github_network_settings_id" {
  description = "The resource ID of the GitHub Network settings resource"
  value       = module.gh_vnet.github_network_settings_id
}

output "github_network_settings_name" {
  description = "Name of the Github Network settings resource"
  value       = module.gh_vnet.github_network_settings_name
}

output "outbound_ip_address" {
  description = "The outbound NAT public IP address used by runners to access the internet"
  value       = module.gh_vnet.outbound_ip_address
}

output "resource_group_id" {
  description = "The resource ID of the resource group containing the resources for the Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners"
  value       = module.gh_vnet.resource_group_id
}
