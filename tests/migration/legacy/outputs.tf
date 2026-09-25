output "github_network_settings_id" {
  description = "GitHub ID of the network settings resource. Changes if the network settings resource is replaced."
  value       = module.gh_vnet.github_network_settings_id
}

output "outbound_ip_address" {
  description = "Public IP of the NAT gateway. Changes if the public IP is replaced."
  value       = module.gh_vnet.outbound_ip_address
}

output "private_endpoint_names" {
  description = "Names of the private endpoints in the module's resource group, sorted."
  value       = sort(data.azapi_resource_list.private_endpoints.output.names)
}

output "private_endpoint_subnet_resource_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = module.gh_vnet.private_endpoint_subnet_resource_id
}

output "resource_group_id" {
  description = "Resource ID of the module's resource group."
  value       = module.gh_vnet.resource_group_id
}

output "runner_nsg_resource_id" {
  description = "Resource ID of the runner subnet's network security group."
  value       = module.gh_vnet.runner_nsg_resource_id
}

output "runner_subnet_resource_id" {
  description = "Resource ID of the runner subnet."
  value       = module.gh_vnet.runner_subnet_resource_id
}

output "virtual_network_resource_id" {
  description = "Resource ID of the virtual network."
  value       = module.gh_vnet.virtual_network_resource_id
}
